# CrossLingPhonotacticProbs78

# About
Data and scripts from Yang, Strand and Cohen Priva, `TODO title`.

# Description
Word lists of words and frequencies for each language are from [the Crúbadán Corpus](http://crubadan.org/).

\#run_all.sh runs all the scripts to output sample lexicons in one file to "samples/". The default is 100 sample lexicons for Turkish and the n-gram model adopted for our study in the paper. Language code, number of samples, as well as the amount of context in n-gram model can all be changed to output different sample lexicons for different languages with different language models. For changing each command's arguments in each step, see detailed annotations of each script involved.

## Folders

Folders with numbers in the beginning of the title contain scripts for each step of the procedure.

Other folders contain products or byproducts from each step. For detailed descriptions and the input and output of each step, check comments in the scripts.

\#Crubadan: Wordlists with wordform and frequency information from the original corpus. Spellchecked wordlists are under "filtered/".  Only one language (Turkish) is listed as an example of word lists used for processing. The same language is used for demonstration purposes in "Example_for_processing_one_language.ipynb" and "run_all_mono_di.sh" as well as "run_all_multi.sh"

\#Crubadan_translate: Wordlists for all 78 languages after translation (output from step 01).

\#mono_di_5000: Core lexicons for all 22 languages (output from step 02) used in our study.

\#language_models: Accumulated counts of every transition in the training lexicon for each language.

\#samples: Samples are too large in size to be kept here. Thus, only files with samples (output from step 04) for Turkish are listed here.



