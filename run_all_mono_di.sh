#!/bin/bash

# 00
Rscript --vanilla 00_Spellcheck_lowercase/main00.R tr Crubadan/tr.txt.bz2 Crubadan/filtered/tr.txt.filtered.bz2

# 01
chmod +x 01_word_to_ipa/main01.sh # works on linux, not mac (argument list too long)
bash 01_word_to_ipa/main01.sh Crubadan/filtered/tr.txt.filtered.bz2 Crubadan/filtered/tr.translate tr

# 02
Rscript --vanilla 02_get_5000/main02_mono_di.R tr Crubadan/filtered/tr.translate mono_di_5000/tr.mono.di.5000 1