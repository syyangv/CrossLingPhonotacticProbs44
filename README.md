# CrossLingPhonotacticProbs78

# About
Data and scripts from Yang, Strand and Cohen Priva, `TODO title`.

# Description
Word lists of words and frequencies for each language are from [the Crúbadán Corpus](http://crubadan.org/). 

- *run_all.sh* runs all the scripts to output sample lexicons (wordforms and phonotactic probabilities) in one file to "samples/". The default is 100 sample lexicons for Turkish. The default parameters for the n-gram model is the same as those adopted for our study in the paper. Language code, number of samples, as well as the amount of context in n-gram model can all be changed to output different sample lexicons for different languages with different language models. For changing each command's arguments in each step, see detailed annotations of each script involved.

- *\*.ipynb* files showcase what scripts for the corresponding step does from start to finish. 

## Folders

Folders with numbers in the beginning of the title contain scripts for each step of the procedure. Step 00 (spellchecking words in corpus) and 01 (translating wordforms to phonemic representation) are not shown here due to the use of data and scripts from other projects. Output from these steps are stored in "Crubadan_translate/" as wordlists with wordforms in ipa representation and frequency counts from the original corpus. 

Other folders contain products or byproducts from each step. For detailed descriptions and the input and output of each step, check comments in the scripts.

- *Crubadan_translate*: Wordlists for all 78 languages after translation. These wordlists are processed and transformed from wordform and frequency data from [the Crúbadán Corpus](http://crubadan.org/). We are displaying them here as approved by the original corpu's [license](http://creativecommons.org/licenses/by/4.0/).
    - Scannell, K. P. 2007. “The Crúbadán Project: Corpus Building for Under­-Resourced Lan­guages.” In *Building and Exploring Web Corpora: Proceedings of the 3rd Web as Corpus Workshop*, 4:5–15.

- *mono_di_5000*: Core lexicons for all 22 languages (output from step 02) used in our study.

- *language_models*: Accumulated counts of every transition in the training lexicon for each language. Each file is a Python dictionary written to YAML format.

- *samples*: Samples are too large in size to be kept here. Thus, only files with samples (output from step 04) of one language are listed here. As with the default argument used for demonstration purposes in *run_all.sh* and *ipynb* files, all sample lexicons here are for Turkish.





