import pandas as pd
import numpy as np

# 1. tool functions

def syl_count(ipa_str):
    nsyl = ipa_str.count("1") + ipa_str.count("0")
    return nsyl

def seg_count(ipa_str):
    nseg = ipa_str.count(" ") + 1
    return nseg

def language_model_count_to_log2_probs(language_model):
    '''
    one language model (of a single syllable length)
    '''
    updated_language_model = {}
    for context, counter in language_model.items():
        context_sum = float(sum(language_model[context][k] for k in language_model[context]))
        updated_language_model[context] = {
            k: np.log2(language_model[context][k] / context_sum) for k in language_model[context]
            }
    return updated_language_model

# 2. randomizing language models

def randomize_language_model_dirichlet(orig_language_model, scale_num = 1000):
    """
    
    params:
    @orig_language_model: a dictionary 
                          key: (ngram) context (context, context_vowels)
                          value: a counter {(seg, vowel_boolean): count}
    output 
    count to log2 probabilities
    """
    updated_language_model = {}
    for context, seg_and_counts in orig_language_model.items():
        df_counts = pd.DataFrame.from_dict(seg_and_counts, orient='index').reset_index()
        df_counts.columns = ['seg', 'counts']
        
        # scale the counts the sample dirichlet probabilities
        df_counts['counts_updated'] = df_counts['counts']*scale_num
        df_counts['probs_updated'] = np.random.dirichlet(df_counts['counts_updated'])
        
        # turn the probabilities to log2
        df_counts['probs_log2'] = np.log2(df_counts['probs_updated'])
        
        updated_seg_and_probs = dict(zip(df_counts.seg, df_counts.probs_log2))
        
        # the new dict for the context
        updated_language_model[context] = updated_seg_and_probs
        
    return updated_language_model

def randomize_language_model_uniform(orig_language_model, max_noise = 1):
    """
    params:
    @orig_language_model: a dictionary 
                          key: (ngram) context
                          value: a counter {seg: count}
    output 
    count to log2 probabilities
    """
    updated_language_model = {}
    for context, seg_and_counts in orig_language_model.items():
        df_counts = pd.DataFrame.from_dict(seg_and_counts, orient='index').reset_index()
        df_counts.columns = ['seg', 'counts']
        
        # add a column of random numbers from 0 to max_noise
        df_counts['unif_noise'] = np.random.random(size = len(df_counts))*max_noise
        df_counts['counts_updated'] = df_counts['counts'] + df_counts['unif_noise']
        df_counts['probs_updated'] = df_counts['counts_updated']/sum(df_counts['counts_updated'])
        
        # turn the probabilities to log2
        df_counts['probs_log2'] = np.log2(df_counts['probs_updated'])
        
        updated_seg_and_probs = dict(zip(df_counts.seg, df_counts.probs_log2))
        
        # the new dict for the context
        updated_language_model[context] = updated_seg_and_probs
        
    return updated_language_model

# 3. assigning probabilties to wordlists (related to assign_probs_to_words.py)
def assign_prob_to_word_only(word, df_syl_count, language_model_all_syl, n_phones = 4, n_vowels = 2):
    """
    assign log2prob to words based on language model (adding log2prob of syllen)
    params:
    @df_syl_count: df with log2prob for each syl_length
    @language_model_all_syl: {syl_length: 
                                (context, vowel_context):
                                    (seg, vowel_bool): 
                                        log2prob}
    """
    
    seg_length = seg_count(word)
    syl_length = syl_count(word)

    segs = tuple(word.split(' '))
    
    # keys for individual segs ('seg', bool)
    vowel_bool = tuple(k.endswith('0') for k in segs)
    segs_key = tuple(i for i in zip(segs, vowel_bool)) + (('', False),)
    
    # keys for contexts ((context), (vowels))
    contexts = []
    for i in np.arange(seg_length + 1):
        contexts.append(segs[:i][-(n_phones - 1):])
    
    vowels_contexts = []
    for i in np.arange(len(contexts)):
        context = contexts[i]
        
        # vowels_contexts[0] == ()
        if len(context) == 0:
            vowels_contexts.append(())
            continue
            
        last_seg = context[-1]
        if last_seg.endswith('0'):
            new_vowel_context = (vowels_contexts[i-1] + (last_seg,))[-n_vowels:]
            vowels_contexts.append(new_vowel_context)
        else:
            vowels_contexts.append(vowels_contexts[i-1])
    
    contexts_key = tuple(i for i in zip(contexts, vowels_contexts))

    # log2prob for the syllen in this language
    df_syl_logprob = df_syl_count.loc[df_syl_count['syllen'] == syl_length].reset_index()
    syl_logprob = df_syl_logprob.loc[0,'logprob']
    
    prob_sum = syl_logprob
    for i in np.arange(seg_length + 1):
        context = contexts_key[i]
        seg = segs_key[i]
        prob_sum += language_model_all_syl[syl_length][context][seg]
    
    return prob_sum

def assign_prob_to_word_syl_known(word, syl_length, df_syl_count, language_model_all_syl, n_phones = 4, n_vowels = 2):
    """
    assign log2prob to words based on language model
    params:
    @df_syl_count: df with log2prob for each syl_length
    @language_model_all_syl: {syl_length: 
                                (context, vowel_context):
                                    (seg, vowel_bool): 
                                        log2prob}
    """
    
    seg_length = seg_count(word)

    segs = tuple(word.split(' '))
    
    # keys for individual segs ('seg', bool)
    vowel_bool = tuple(k.endswith('0') for k in segs)
    segs_key = tuple(i for i in zip(segs, vowel_bool)) + (('', False),)
    
    # keys for contexts ((context), (vowels))
    contexts = []
    for i in np.arange(seg_length + 1):
        contexts.append(segs[:i][-(n_phones - 1):])
    
    vowels_contexts = []
    for i in np.arange(len(contexts)):
        context = contexts[i]
        
        # vowels_contexts[0] == ()
        if len(context) == 0:
            vowels_contexts.append(())
            continue
            
        last_seg = context[-1]
        if last_seg.endswith('0'):
            new_vowel_context = (vowels_contexts[i-1] + (last_seg,))[-n_vowels:]
            vowels_contexts.append(new_vowel_context)
        else:
            vowels_contexts.append(vowels_contexts[i-1])
    
    contexts_key = tuple(i for i in zip(contexts, vowels_contexts))

    # log2prob for the syllen in this language
    df_syl_logprob = df_syl_count.loc[df_syl_count['syllen'] == syl_length].reset_index()
    syl_logprob = df_syl_logprob.loc[0,'logprob']
    
    prob_sum = syl_logprob
    for i in np.arange(seg_length + 1):
        context = contexts_key[i]
        seg = segs_key[i]
        prob_sum += language_model_all_syl[syl_length][context][seg]
    
    return prob_sum

# 4. sampling a single lexicon with chosen randomization

def sampling_from_enum_with_dirichlet_lm(enum_pool_dict_all, df_log2prob_by_syl, orig_seg_syl_df, lm_orig_dict, scale_num = 1000):
    """
    get a sample lexicon with a orig language model
    params:
    @enum_pool_dict_all: enumerated words of all syllable lengths 
        (filtered to make sure that all words are shorter than max_seglen,
         enumerated words for each syllable length is of that syllable length)
    @orig_seg_syl_df: original lexicon with words shorter than max_seglen, 
        df with counts of seg-syl combination
    @lm_orig: original language model
    -> new_lexicon
    """
    # 1. get a new randomized language model for every syllable length -> lm_dict_update: sy_len: {context: (seg, prob)}
    lm_dict_update = {}
    for syl_len in enum_pool_dict_all:
        lm_dict_update[syl_len] = randomize_language_model_dirichlet(lm_orig_dict[syl_len], scale_num)

    # 2. assign new probs to enum_pool + pr(syl) for each syllable length
    for syl_len in lm_orig_dict:
        enum_pool_dict_all[syl_len]['logprob'] = enum_pool_dict_all[syl_len]['ipa'].apply(
            assign_prob_to_word_syl_known, 
            args = (syl_len, df_log2prob_by_syl, lm_dict_update))

    # 3. get one sample for each syllen+seglen combination
    new_lexicon = pd.DataFrame()
    for i in np.arange(len(orig_seg_syl_df)): # for one row in seg-syl df
        # sampling one seg-syl combination
        syl_len = orig_seg_syl_df.at[i, 'syllen']
        seg_len = orig_seg_syl_df.at[i, 'seglen']
        count = orig_seg_syl_df.at[i, 'count']
        wordlist_syl = enum_pool_dict_all[syl_len]

        # subset enum words to be sampled from
        source = wordlist_syl[wordlist_syl.seglen == seg_len][['ipa', 'logprob']]

        # normalize probabilities for words to be sampled based on 
        p_source = source.logprob
        new_p = np.power(2, p_source)
        new_p /= new_p.sum()

        sampled_indices = np.random.choice(source.index, count, replace = False, p = new_p)

        words_output = source.loc[sampled_indices, ]
        words_output['seglen'] = seg_len
        words_output['syllen'] = syl_len

        new_lexicon = pd.DataFrame.append(new_lexicon, words_output)

    return new_lexicon

def sampling_from_enum_with_uniform_lm(enum_pool_dict_all, df_log2prob_by_syl, orig_seg_syl_df, lm_orig_dict, max_noise = 1):
    """
    get a sample lexicon with a orig language model
    params:
    @enum_pool_dict_all: enumerated words of all syllable lengths 
        (filtered to make sure that all words are shorter than max_seglen,
         enumerated words for each syllable length is of that syllable length)
    @orig_seg_syl_df: original lexicon with words shorter than max_seglen, 
        df with counts of seg-syl combination
    @lm_orig: original language model
    -> new_lexicon
    """
    # 1. get a new randomized language model for every syllable length -> lm_dict_update: sy_len: {context: (seg, prob)}
    lm_dict_update = {}
    for syl_len in enum_pool_dict_all:
        lm_dict_update[syl_len] = randomize_language_model_uniform(lm_orig_dict[syl_len], max_noise)

    # 2. assign new probs to enum_pool + pr(syl) for each syllable length
    for syl_len in lm_orig_dict:
        enum_pool_dict_all[syl_len]['logprob'] = enum_pool_dict_all[syl_len]['ipa'].apply(
            assign_prob_to_word_syl_known, 
            args = (syl_len, df_log2prob_by_syl, lm_dict_update))

    # 3. get one sample for each syllen+seglen combination
    new_lexicon = pd.DataFrame()
    for i in np.arange(len(orig_seg_syl_df)): # for one row in seg-syl df
        # sampling one seg-syl combination
        syl_len = orig_seg_syl_df.at[i, 'syllen']
        seg_len = orig_seg_syl_df.at[i, 'seglen']
        count = orig_seg_syl_df.at[i, 'count']
        wordlist_syl = enum_pool_dict_all[syl_len]

        # subset enum words to be sampled from
        source = wordlist_syl[wordlist_syl.seglen == seg_len][['ipa', 'logprob']]

        # normalize probabilities for words to be sampled based on 
        p_source = source.logprob
        new_p = np.power(2, p_source)
        new_p /= new_p.sum()

        sampled_indices = np.random.choice(source.index, count, replace = False, p = new_p)

        words_output = source.loc[sampled_indices, ]
        words_output['seglen'] = seg_len
        words_output['syllen'] = syl_len

        new_lexicon = pd.DataFrame.append(new_lexicon, words_output)

    return new_lexicon


