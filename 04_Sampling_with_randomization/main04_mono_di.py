import sys
import csv
import pandas as pd
import yaml
import bz2
import os
import numpy as np
from time import gmtime, strftime
from datetime import datetime
from assign_probs_to_words import *
from randomize_language_models_and_sampling import *
yaml.warnings({'YAMLLoadWarning': False})

def main():
    if len(sys.argv) != 7:
        print(
            "Incorrect number of arguments. Usage: python3.7 04_Sampling_with_randomization/main04.py <lowercase_language_code> <int> <int> <int> <int> <boolean>"
        )
        exit()

    script, LanCode, n_phones, n_vowels, num_rounds, sample_num, write_real_probs = sys.argv

    n_phones = int(n_phones)
    n_vowels = int(n_vowels)
    num_rounds = int(num_rounds)
    num_max_segs = num_rounds - 1
    sample_num = int(sample_num)
    write_real_probs = bool(int(write_real_probs))


    # 0. check the number of samples in the directory
    print('current samples: ' + str(len([name for name in os.listdir('samples/mono_di/' + LanCode)])))
    if len([name for name in os.listdir('samples/mono_di/' + LanCode)]) >= sample_num:
        exit()

    # 1. import language models and sizes for each syllable length
    ## 1.1 get language model
    lm_dict_path = 'language_models/mono_di/' + LanCode + '.LM.bysyl'
    with bz2.open(lm_dict_path) as dbfile:
        #lm_dict = yaml.load(dbfile)
        lm_dict = yaml.unsafe_load(dbfile)

    ## 1.2 get orig lexicon
    words_path = ("mono_di_5000/" + LanCode + ".5000")
    
    print(words_path)
    words = pd.read_csv(words_path, sep = '\t')
    words["syllen"] = words.ipa.map(lambda x: syl_count(x))
    words["seglen"] = words.ipa.map(lambda x: seg_count(x))

    ## 1.3 log2prob for each syllable length according to the real orig lexicon
    words_total_count = len(words)
    df_counts_bysyl = words.groupby(['syllen']).size().reset_index(name = 'counts')
    df_counts_bysyl['logprob'] = np.log2(df_counts_bysyl.counts/words_total_count)

    ## 1.4 real lexicon to be used for comparison (filtered orig lexicon)
    words_update = words[words.seglen <= num_max_segs]

    # get sizes for every syllable length (subset)
    syl_array = words_update['syllen'].unique()

    # write real lexicon to csv given the boolean
    if write_real_probs:
        real_lexicon_writename = ('samples/mono_di/'
            + LanCode
            + '.'
            + 'real.lex.bz2'
            )

        # turn counts in language models to log2probs 
        lm_dict_real = {}
        for syl_len in syl_array:
            lm_dict_real[syl_len] = language_model_count_to_log2_probs(lm_dict[syl_len])
        # assign probabilities from log2probs of the original counts (with syllable log2prob)
        words_update['logprob'] = words_update['ipa'].apply(
            assign_prob_to_word_only,
            args = (df_counts_bysyl, lm_dict_real)
            )
        words_update.to_csv(real_lexicon_writename, index = False, compression = 'bz2')

    
    wordlist_bysyl = {}
    for syl_len in syl_array:
        wordlist_bysyl[syl_len] = words_update[words_update.syllen == syl_len]

    words_update_len = words_update[['syllen', 'seglen']]

    # sizes for each syl-seg combination
    len_usable_df = pd.DataFrame(
        words_update_len.groupby(
            [words_update_len['syllen'],
             words_update_len['seglen']]
            ).size()
        ).reset_index()

    len_usable_df.columns = ['syllen', 'seglen', 'count']

    if write_real_probs:
        len_usable_df_writename = ('samples/mono_di/'
            + LanCode
            + '.lengths.df.csv'
            )

        len_usable_df.to_csv(len_usable_df_writename, index = False)

    # 2. import enumerated words for each syllable length
    enum_path_base = 'mono_di_5000/bySyl/' + LanCode + '.enum.word.10.syl'
    ## 2.1 get filtered enumerated words by each syllable length
    enum_bysyl = {}
    for syl_len in syl_array:
        syl = pd.read_csv(enum_path_base + str(syl_len) + '.csv', sep = ',')
        syl.columns = ['ipa', 'seglen']

        # only keep enumerated words that match the number of syllables
        syl['syllen'] = syl['ipa'].apply(syl_count)
        syl_filtered = syl[syl['syllen'] == syl_len]
        enum_bysyl[syl_len] = syl_filtered

    ## 2.2 get len_seg_syl for enumerated words
    enum_words = pd.concat([enum_bysyl[i] for i in syl_array])

    enum_words_len = enum_words[['syllen', 'seglen']]

    enum_len_usable_df = pd.DataFrame(
        enum_words_len.groupby(
            [enum_words_len['syllen'],
             enum_words_len['seglen']]
            ).size()
        ).reset_index()
    enum_len_usable_df.columns = ['syllen', 'seglen', 'count']

    ## 2.3  check if there are enough enum words - for each syl-seg comb, there are more enum than orig
    enum_len_usable_df = enum_len_usable_df.astype({'syllen': 'int64', 'seglen': 'int64'})
    len_usable_df_all = pd.merge(len_usable_df, enum_len_usable_df, on = ['syllen', 'seglen'])
    len_usable_df_all.columns = ['syllen', 'seglen', 'count_orig', 'count_enum']
    len_usable_df_all['lack_enum'] = (len_usable_df_all['count_enum'] - len_usable_df_all['count_orig']) < 0

    if sum(len_usable_df_all.lack_enum) > 0:
        print(LanCode + ' not enough enum')
        exit()

    # 3. one sample lexicon
    ## 3.1 check the number of samples in the directory again
    while len([name for name in os.listdir('samples/mono_di/' + LanCode)]) < sample_num:
        new_sample = sampling_from_enum_with_dirichlet_lm(enum_bysyl, df_counts_bysyl, len_usable_df, lm_dict)
        now = datetime.now()
    # 4. write the sampled lexicon to csv with timestamp
        sample_writename = ('samples/mono_di/' + 
            LanCode + '/'
            + 'sample.'
            + str(now.month) + str(now.day) + '_' 
            + str(now.hour) + str(now.minute) + str(now.second) + '_' 
            + str(now.microsecond)
            + '.bz2'
            )
        new_sample.to_csv(sample_writename, index = False, compression = 'bz2')


if __name__ == "__main__":
    main()