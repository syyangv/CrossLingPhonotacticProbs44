rm(list = ls())
options(stringsAsFactors = F)
library(tidyverse)
library(stringi)
library(tm)

args = commandArgs(trailingOnly = TRUE)

#args <- c('ay', 'Crubadan/filtered/ay.translate', 'mono_di_5000/ay.mono.di.5000', '1')

# part 0: sys and input ####
if (length(args) != 4){
  print('Incorrect number of argments. Usage: Rscript --vanilla <script_name>.R EN <option> <path_to_samples>')
  quit()
} else{
  LanCode <- args[1]
  input_filename <- args[2]
  output_filename <- args[3]
  get_mono_di <- as.logical(as.numeric(args[4]))
}
print(paste('the current language is', LanCode))
print(paste('input from', input_filename))

words <- read_tsv(input_filename)
colnames(words)[2] <- 'ipa'

# exclude words with @ signs ----
words <- words %>% mutate(exclude = str_detect(ipa, '@'))

cat('For', LanCode, 'excluding', nrow(subset(words, exclude))/nrow(words), 'of current types\n')
cat('For', LanCode, 'excluding', sum(subset(words, exclude)$freq)/sum(words$freq), 'of current tokens\n')

words_retain <- subset(words, !exclude) %>% select(-exclude)

# collapse frequencies for homophones ----

words_new <- words_retain %>% group_by(ipa) %>%
  summarise(word = word[1], freq = sum(freq)) %>%
  arrange(desc(freq)) %>%
  mutate(ipa = str_replace_all(ipa, ' ː', 'ː'), # change xpf transcription, elongation mark to immediately follow every segment
         ipa = str_replace_all(ipa, '[0-9]', ''))

# mark all vowels ----
all_vowels_ipa <- 'i,y,ɨ,ʉ,ɯ,u,ɪ,ʏ,ʊ,e,ø,ɘ,ɵ,ɤ,o,o̞,ɛ,œ,ɜ,ɞ,ʌ,ɔ,æ,ɐ,a,ɶ,ɑ,ɒ,ɔ̃,ɑ̃,ə,ɚ,ɪ̈,ɝ,ɛ̃'
all_vowels_match <- str_replace_all(all_vowels_ipa, ',', '|')
all_unstressed_vowels_match <- paste0('(', all_vowels_match, ')(ː?)( |$)')

words_new <- words_new %>% ungroup() %>% rowwise() %>%
  mutate(ipa = str_replace_all(ipa, all_unstressed_vowels_match, '\\1\\20\\3'))

words_new <- words_new %>% ungroup() %>% group_by(ipa) %>%
  summarise(word = word[1], freq = sum(freq)) %>% arrange(desc(freq))

# eliminate words without vowels -- 0-syllable ----
words_new <- subset(words_new, str_detect(words_new$ipa, '0'))

# remove types whose tokens are more than or equal to 0.1% frequencies of all tokens ----
sum_lan_token_freq <- sum(words_new$freq)
function_words_threshold_percentage <- 0.1
words_source <- subset(words_new, freq < sum_lan_token_freq * function_words_threshold_percentage * 0.01)
cat('excluding words whose frequencies are more or equal as the 0.1% of all token frequencies for (filtered) valid words for the language\n')
cat('orig number of words: ', nrow(words_new), '\n')
cat('number of retained words: ', nrow(words_source), '\n')
cat('cutoff threshold: ', sum_lan_token_freq * function_words_threshold_percentage * 0.01, '\n')

words_source$syllen <- str_count(words_source$ipa, '0')

if (get_mono_di){
  words_source_mono_di <- subset(words_source, syllen <= 2)
  if (nrow(words_source_mono_di) < 5000){
    cat('not enough mono/di words for', LanCode,'\n')
    quit()
  }else{
    threshold_freq <- words_source_mono_di[5000, ]$freq
    if (threshold_freq < 4){
      cat('not enough words for', LanCode, '\n')
      quit()
    }else{
      words_n <- subset(words_source_mono_di, freq >= threshold_freq)
      cat('For', LanCode, 'number of monosyllabic and disyllabic wordforms with 5000 highest frequencies:\n', nrow(words_n), '\n')
      cat('For', LanCode, 'cut-off frequency is:\n', threshold_freq, '\n')
    }
  }
}else{
  # get 5000 words
  if (nrow(words_source) < 5000){
    cat('not enough words for', LanCode,'\n')
    quit()
  }else{
    threshold_freq <- words_source[5000, ]$freq
    if (threshold_freq < 5){
      cat('not enough words for', LanCode,'\n')
      quit()
    }else{
      words_n <- subset(words_source, freq >= threshold_freq)
      cat('For', LanCode, 'number of wordforms with 5000 highest frequencies:\n', nrow(words_n), '\n')
      cat('For', LanCode, 'cut-off frequency is:\n', threshold_freq, '\n')
    }
  }
}


write_tsv(words_n, output_filename)


