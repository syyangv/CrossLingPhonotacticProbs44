import sys
import gzip
import csv
import pandas as pd
import bz2
import yaml
from time import gmtime, strftime
from ngram_model_and_enumerate import *

def write_enum(filename, args_list):
    if len(args_list) == 0:
        sys.exit("empty dataset")
    enumerated_wordlist = []
    enumerated_wordlen = []

    for i in args_list:
        enumerated_wordlist.append(" ".join(i[2]))
        enumerated_wordlen.append(i[1])

    all_words = []
    for i, k in zip(enumerated_wordlist, enumerated_wordlen):
        all_words.append((i, k))

    with open(filename, "w") as f:
        writer = csv.writer(f)
        writer.writerow(("word", "len"))
        for line in all_words:
            writer.writerow(line)
    print(strftime("%Y-%m-%d %H:%M:%S", gmtime()))
    print("{} is created".format(filename))

def syl_count(ipa_str):
    nsyl = ipa_str.count("1") + ipa_str.count("0")
    return nsyl


def seg_count(ipa_str):
    nseg = ipa_str.count(" ") + 1
    return nseg


def main():
    if len(sys.argv) != 5:
        print(
            "Incorrect number of arguments. Usage: python3.7 03_Language_Model/main03_mono_di.py <lowercase_language_code> <int> <int> <int>"
        )
        exit()

    script, LanCode, n_phones, n_vowels, num_rounds = sys.argv

    words_path = ("mono_di_5000/" + LanCode + ".mono.di.5000")
    db_path = ("language_models/mono_di/" + LanCode + ".LM.bysyl")
    print(words_path)

    n_phones = int(n_phones)
    n_vowels = int(n_vowels)
    num_rounds = int(num_rounds)
    num_max_segs = num_rounds - 1

    words = pd.read_csv(words_path, sep="\t")
    words["syllen"] = words.ipa.map(lambda x: syl_count(x))
    words["seglen"] = words.ipa.map(lambda x: seg_count(x))
    # all available syllable lengths
    syl_array = words["syllen"].unique()
    print(syl_array)

    db = {}
    #db_counts = {}
    for syl_len in syl_array:
        # globals()['words_syl' + str(i)] = words[words.syllen == i]
        # words with syllen == i
        df_words = words[words.syllen == syl_len]
        seglen_counts = df_words.groupby(['seglen']).size().reset_index(name = 'counts')
        wordlist = list(df_words.ipa)
        max_seglen = max(df_words.seglen)
        min_seglen = min(df_words.seglen)
        # get language model
        print("model for", LanCode, "with syllen =", syl_len)
        lex_model = n_phone_model_count_vowels(
            n=n_phones, num_vowels=n_vowels, wordseglist=wordlist
            )
        #db_counts[syl_len] = seglen_counts

        # if all words in this syllable length is longer than 10 segments
        # drop the syllen
        if num_max_segs < min_seglen:
            print('skip', syl_len)
            continue

        # update enumerated length of words
        if num_max_segs > max_seglen:
            num_max_segs_update = max_seglen
            num_rounds_update = num_max_segs_update + 1
        else:
            num_max_segs_update = num_max_segs
            num_rounds_update = num_rounds

        # enumerate all words up to 10 segments (11 rounds)
        enumerated_args = EnumerateEnd_count_vowels(
            lex_model, round=num_rounds_update
            )

        if len(enumerated_args) == 0:
            print('skip', syl_len)
            continue

        enumerated_wordlist = []

        """
        check if all words in the lexicon up to num_max_segs have been generated
        """
        for i in enumerated_args:
            enumerated_wordlist.append(" ".join(i[2]))
            
        for i in wordlist:
            j = i.replace("1", "0")
            if j in enumerated_wordlist:
                continue
            elif i.count(" ") + 1 > num_max_segs:
                continue
            else:
                print(LanCode, "error, fail to generate:", j)

        enum_writename = (
            "Crubadan5000/bySyl/"
            + LanCode
            + ".enum.word."
            + str(num_max_segs)
            + ".syl"
            + str(syl_len)
            + ".csv"
            )
        db[syl_len] = lex_model
        write_enum(enum_writename, enumerated_args)

    with bz2.open(db_path, 'wt') as dbfile:
        yaml.dump(db, dbfile)
    #with bz2.open(db_counts_path, 'wt') as db_counts_file:
    #    yaml.dump(db_counts, db_counts_file)




if __name__ == "__main__":
    main()