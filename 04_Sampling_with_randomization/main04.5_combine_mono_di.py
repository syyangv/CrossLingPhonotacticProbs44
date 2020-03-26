import sys
import csv
import pandas as pd
import yaml
import bz2
import os
import numpy as np
from time import gmtime, strftime
from assign_probs_to_words import *
from randomize_language_models_and_sampling import *

'''
collating all individual samples in a folder to one dataframe (one file)
'''

def main():
    if len(sys.argv) != 2:
        print(
            "Incorrect number of arguments."
        )
        exit()

    script, LanCode = sys.argv

    sample_lexicons = pd.DataFrame()
    for i, name in enumerate(os.listdir('samples/mono_di/' + LanCode)):
        sample_i = i + 1
        with bz2.open('samples/mono_di/'+LanCode+'/'+name, "rb") as f:
            new_sample = pd.read_csv(f)
        new_sample['SampleNo'] = sample_i
        sample_lexicons = pd.DataFrame.append(sample_lexicons, new_sample)

    sample_num = len([name for name in os.listdir('samples/mono_di/' + LanCode)])

    samples_writename = ('samples/mono_di/'
        + LanCode
        + '.'
        + str(sample_num)
        + '.samples.bySyl.bz2'
        )
    
    sample_lexicons.to_csv(samples_writename, index = False, compression = 'bz2')


if __name__ == "__main__":
    main()