#!/bin/bash

input_filepath="$1"
output_filepath="$2"
lancode="$3"
#echo $lancode

rule_dir=$(find 01_word_to_ipa/XPF -maxdepth 1 -type d -name "$lancode\_*" -print)
rule_dir_update="${rule_dir}/$lancode.rules"

echo "directory to rules: $rule_dir_update"

python3.7 01_word_to_ipa/translate04.py -l "$rule_dir_update" $(bzcat "$input_filepath" | awk -F"," '{print $1}') > "${output_filepath}_draft"

paste -d'\t' "${output_filepath}_draft" <(bzcat "$input_filepath" | awk -F"," '{print $2}') > "$output_filepath"

rm "${output_filepath}_draft"
