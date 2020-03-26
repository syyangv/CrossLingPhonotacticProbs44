import numpy as np
from collections import Counter, defaultdict
import sys



def n_phone_model_count_vowels(wordseglist, n=4, num_vowels=2):
    """
    params:
    @wordseglist: a list of all words available for building the n-phone model
    @n: the span of strings to be considered for the model (n-phone model)
    @num_vowels: the number of vowels to be considered as part of the previous context
    returns:
    @probsincontext
    e.g.
    {(context1, context_vowels1):
        {seg1: #(context1, context_vowels1)seg1/#(context1, context_vowels1), 
         seg2: #(context1, context_vowels1)seg2/#(context1, context_vowels1)},
     (context2, context_vowels2):
        {seg1: #(context2, context_vowels2)seg1/#(context2, context_vowels2),
         seg2: #(context2, context_vowels2)seg2/#(context2, context_vowels2)}}
    a dict whose key points to a context (a tuple with up to n-1 segments)
    the value points to a dict whose key is the nth segment 
    (a tuple with the nth seg and a frozenset pointing to whether this new segment is stressed)
    """
    counts = defaultdict(Counter)
    """
    e.g.
    {(context1, context_vowels1):
        {(seg1, boolean_vowels): count, 
         (seg2, boolean_vowels): count},
     (context2, context_vowels2):
        {(seg1, boolean_vowels): count, 
         (seg2, boolean_vowels): count}}
    a defaultdict whose key points to a context (a tuple with up to n-1 segments)
    the value points to a counter whose key is the nth segment 
    (a tuple with the nth seg and a frozenset pointing to whether this new segment is stressed)
    """
    for word in wordseglist:
        # turn stressed vowels into regular vowels
        # so that stressed and unstressed vowels do not differ
        word = word.replace("1", "0")
        segs = tuple(word.split(" "))  # list all segments in the word
        vowels = []
        vowels_index = []
        for index, seg in enumerate(segs):
            if seg.endswith("1") or seg.endswith("0"):
                vowels.append(seg)
                vowels_index.append(index)

        # list all vowels in the word by order of appearance
        vowels = tuple(vowels)
        # list all vowel indices in the word by order of appearance
        vowels_index = np.array(vowels_index)

        for index, seg in enumerate(segs):
            # get the last 2 vowels from the list of vowels preceding the current segment
            if len(np.nonzero(vowels_index < index)[0]) == 0:
                context_vowel = ()
            else:
                slicing_index = max(np.nonzero(vowels_index < index)[0]) + 1
                context_vowel = vowels[:slicing_index][-num_vowels:]
            # if the current segment is a vowel or not
            if seg.endswith("1") or seg.endswith("0"):
                vowel_bool = True
            else:
                vowel_bool = False
            context = segs[:index][-(n - 1) :]
            counts[(context, context_vowel)][(seg, vowel_bool)] += 1
        counts[(segs[-(n - 1) :], vowels[-num_vowels:])][
            ("", False)
        ] += 1  # end of the word
    return counts

'''
ProbsInContext = {}
    for context, counter in counts.items():
        context_sum = float(sum(counts[context][k] for k in counts[context]))
        ProbsInContext[context] = {
            k: np.log2(counts[context][k] / context_sum) for k in counts[context]
        }
return ProbsInContext
'''

def EnumerateNext_count_vowels(
    language_model, args = (tuple(), 0, tuple(), tuple()), 
    n = 4, num_vowels = 2
    ):
    """
    given n-phone model, enumerate to a next segment
    params:
    @language_model: output of n_phone_model_count_vowels(), the n-phone language model
    @args: defined as the following
    @n: same as the n in n_phone_model_count_vowels()
    """
    initContext = args[0]
    startlen = args[1]
    initWord = args[2]
    initContext_vowels = args[3]
    if "" in initContext:  # the word has ended
        return
    else:
        for seg, seg_count in language_model[(initContext, initContext_vowels)].items():
            newContext = (initContext + (seg[0],))[-(n - 1) :]
            if (
                seg[0] == ""
            ):  # the current segment is empty, suggesting the word has ended
                if (
                    len(initContext_vowels) == 0
                ):  # there must be at least a vowel in the word
                    continue
                else:
                    yield (
                        newContext,
                        startlen,
                        initWord,
                        initContext_vowels,
                    )
            else:
                if seg[1]:  # the current segment is a vowel
                    newContext_vowels = (initContext_vowels + (seg[0],))[-num_vowels:]
                    yield (
                        newContext,
                        startlen + 1,
                        initWord + (seg[0],),
                        newContext_vowels,
                    )
                else:
                    yield (
                        newContext,
                        startlen + 1,
                        initWord + (seg[0],),
                        initContext_vowels,
                    )

def EnumerateEnd_count_vowels(
    language_model, args=(tuple(), 0, tuple(), tuple()), round=9
):
    """
    enumerate 8 rounds and get all possible words up to 8-1 = 7 segments
    params:
    @language_model: n-phone model
    @args: starting point, default is empty
    @round: number of rounds for enumeration

    returns:
    @list_complete: a list of complete words from enumeration
    """
    list_complete = []

    def recurse_count_vowels(arg, round_left):
        if round_left == 0:
            sys.exit("Enumeration cannot start with 0 round.")
        if "" in arg[0]:  # word complete
            list_complete.append(arg)  # no need to enumerate more for this word
        else:
            gen_one_round = EnumerateNext_count_vowels(language_model, args=arg)
            if round_left == 1:  # no more rounds after this
                for a in gen_one_round:  # stop here, collect all complete words
                    if "" in a[0]:
                        list_complete.append(a)
            else:
                for a in gen_one_round:
                    recurse_count_vowels(a, round_left - 1)

    recurse_count_vowels(arg=args, round_left=round)
    return list_complete









