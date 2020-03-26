import numpy as np
import pandas as pd

def assign_prob_to_word(word, seg_length, syl_length, df_syl_count, language_model_all_syl, n_phones = 4, n_vowels = 2):
    """
    assign log2prob to words based on language model
    params:
    @df_syl_count: df with log2prob for each syl_length
    @language_model_all_syl: {syl_length: 
                                (context, vowel_context):
                                    (seg, vowel_bool): 
                                        log2prob}
    """
    
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
