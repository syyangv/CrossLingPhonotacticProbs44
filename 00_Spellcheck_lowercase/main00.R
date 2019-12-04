rm(list = ls())
options(stringsAsFactors = F)
library(tidyverse)
library(stringi)
library(tm)

args = commandArgs(trailingOnly = TRUE)

#setwd('~/Dropbox (Brown)/CrossLing_Crubadan/')
#args <- c('chr', 'Crubadan/chr.txt.bz2', 'Crubadan/filtered/chr.txt.filtered.bz2')

# part 0: sys and input ####
if (length(args) != 3){
  print('Incorrect number of argments. Usage: Rscript --vanilla <script_name>.R EN <option> <path_to_samples>')
  quit()
} else{
  LanCode <- args[1]
  input_filename <- args[2]
  output_filename <- args[3]
#  output_filename <- paste0('Crubadan/filtered/', args[3])
#  word_file <- paste0('OpenSubtitles2018/', LanCode, '.word.filtered.count.csv')
#  word_output_file <- paste0('OpenSubtitles2018/', LanCode, '.word.lowercase.count.csv')
}
print(paste('the current language is', LanCode))
print(paste('input from', input_filename))

aspell_list <- read_csv('00_Spellcheck_lowercase/aspell.ll', col_names = FALSE) %>% pull(X1)

aspell_bool <- LanCode %in% aspell_list

words <- read_delim(input_filename, delim = ' ', col_names = FALSE)
colnames(words) <- c('word', 'freq')

# part 1: data wrangling ####
# remove na and empty string
words <- words %>% rowwise() %>% drop_na()

# remove remaining punctuation marks not in the middle of the word
words$word <- str_replace_all(words$word, '^[[:punct:]]*', '')
words$word <- str_replace_all(words$word, '[[:punct:]]*$', '')
words <- words %>% ungroup() %>%
  group_by(word) %>%
  summarise(freq = sum(as.numeric(freq))) %>% arrange(desc(freq))

# remove empty strings which might have inccurred becasue of the previous procedure
if (length(which(words$word == '')) > 0){
  words <- words[-which(words$word == ''),]
}

# part 2: aspell and removing uppercases####
if (!aspell_bool){
  token_count_orig <- sum(as.numeric(words$freq))
  type_count_orig <- nrow(words)
  words$lower <- tolower(words$word)

  #remove uppercase words in respective scripts
  words <- words %>% mutate(includeupper = !(word == lower))
  words_upper <- subset(words, includeupper) %>%
    ungroup() %>%
    group_by(lower) %>%
    summarise(freq = sum(freq))
  words_lower <- subset(words, !includeupper) %>%
    ungroup() %>%
    group_by(word) %>%
    summarise(freq = sum(freq))

  words_filtered <- words_lower %>%
    left_join(words_upper, by = c('word' = 'lower')) %>%
    ungroup() %>% rowwise() %>%
    mutate(freq = sum(freq.x, freq.y, na.rm = TRUE)) %>%
    select(word, freq)
}else{
  if (LanCode == 'en'){
    # cleaning in aspell mistakenly cleans out characters in other languages
    # so it's only applied to English
    writeLines(words$word, con = 't1.txt')
    pasted_command_clean <- 'cat t1.txt | aspell --lang=en clean 2>/dev/null'

    aspell_cleaned <- readLines(p <- pipe(pasted_command_clean))
    close(p)

    words_cleaned <- words[which(words$word %in% aspell_cleaned), ]
    words_eliminated <- words[-which(words$word %in% aspell_cleaned), ]
    writeLines(words_cleaned$word, con = 't2.txt')

    token_count_orig <- sum(as.numeric(words_cleaned$freq))
    type_count_orig <- nrow(words_cleaned)

    pasted_command <- 'cat t2.txt | aspell --lang=en_US --list'
  }else{
    writeLines(words$word, con = 't1.txt')
    token_count_orig <- sum(as.numeric(words$freq))
    type_count_orig <- nrow(words)

    words_cleaned <- words

    pasted_command <- paste0('cat t1.txt | aspell --lang=', LanCode, ' --list')
  }
  aspell_errors <- readLines(p <- pipe(pasted_command))
  close(p)
  words_aspelled <- words_cleaned[-which(words_cleaned$word %in% aspell_errors), ]
  words_ungrammatical <- words_cleaned[which(words_cleaned$word %in% aspell_errors), ]

  if (length(which(words_aspelled$word == '')) > 0){
    words_aspelled <- words_aspelled[-which(words_aspelled$word == ''),]
  }

  if (LanCode != 'de'){
    # remove uppercase words from words_aspelled whose lowercase forms are not grammatical e.g. Paris vs. paris
    # collapse frequencies of upper- and lower-cases

    words_aspelled$lower <- tolower(words_aspelled$word)
    words_aspelled <- words_aspelled %>% mutate(includeupper = !(word == lower))
    words_aspelled_upper <- subset(words_aspelled, includeupper) %>%
      ungroup() %>%
      group_by(lower) %>%
      summarise(freq = sum(freq))
    words_aspelled_lower <- subset(words_aspelled, !includeupper) %>%
      ungroup() %>%
      group_by(word) %>%
      summarise(freq = sum(freq))

    words_aspelled_filtered <- words_aspelled_lower %>%
      left_join(words_aspelled_upper, by = c('word' = 'lower')) %>%
      ungroup() %>% rowwise() %>%
      mutate(freq = sum(freq.x, freq.y, na.rm = TRUE)) %>%
      select(word, freq)

    # add collapsed tokens back from words_ungrammatical to corresponding lowercase forms,
    words_ungrammatical$word <- tolower(words_ungrammatical$word)
    words_ungrammatical <- words_ungrammatical %>%
      ungroup() %>% group_by(word) %>%
      summarise(freq = sum(as.numeric(freq))) %>%
      arrange(desc(freq))

    words_filtered <- words_aspelled_filtered %>%
      left_join(words_ungrammatical, by = 'word') %>% rowwise() %>%
      transmute(word = word, freq = sum(freq.x, freq.y, na.rm = TRUE))
    }else{
      #de #risk: still contain German names and proper nouns
      # do not add back tokens of ungrammatical identical words
      words_aspelled$lower <- tolower(words_aspelled$word)
      words_filtered <- words_aspelled %>% select(lower, freq) %>%
        group_by(lower) %>% summarise(freq = sum(as.numeric(freq))) %>%
        rename(word = lower) %>%
        arrange(desc(freq))
    }
}

words_filtered <- words_filtered %>% ungroup() %>% arrange(desc(freq))
#nrow(words_filtered)

#
# words_filtered <- words_filtered %>% mutate(word = str_replace_all(word, '-+', '-'),
#                                             dash = str_count(word, '-'))
# words_dash <- subset(words_filtered, dash > 0)
# words_retain <- subset(words_filtered, dash == 0) %>% select(-dash)
#
# words_dash <- words_dash %>% mutate(n = dash + 1)
#
# words_dash <- words_dash[rep(rownames(words_dash), words_dash$n), 1:2]

# percentage of tokens and types left after spellchecking
cat(paste('For', LanCode, 'the percentage of retained tokens after removing uppercase words is\n',sum(words_filtered$freq)/token_count_orig, '\n'))
cat(paste('For', LanCode, 'the percentage of retained types after removing uppercase words is\n',nrow(words_filtered)/type_count_orig, '\n'))
cat(paste('For', LanCode, 'the number of retained types\n', nrow(words_filtered), '\n'))

write_csv(words_filtered, bzfile(output_filename))
cat(paste('lowercase words and frequencies', LanCode, 'are written to\n', output_filename))
