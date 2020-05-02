#!/bin/bash

# 02
Rscript --vanilla 02_get_5000/main02_mono_di.R tr Crubadan/filtered/tr.translate mono_di_5000/tr.mono.di.5000 1

# 03 
python3.7 03_Language_Model/main03_mono_di.py tr 4 2 11

# 04 100 samples
python3.7 04_Sampling_with_randomization/main04_mono_di.py tr 4 2 11 100 1
python3.7 04_Sampling_with_randomization/main04.5_combine_mono_di.py tr


