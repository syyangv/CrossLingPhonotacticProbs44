rm(list = ls())
library(tidyverse)
options(stringsAsFactors = F)

#setwd('~/Dropbox (Brown)/CrossLing_Crubadan_dirichlet_mono_di/')

# background variables ----

objects <- c('len_usable_df', 'samples', 'real_lex')
dir.create(file.path('stats/'))


lancodes <- read.csv('06_Stats/lancode_list') %>% pull()

# functions ----
get_parameters_multi <- function(samples_df){
  params <- samples_df %>% ungroup() %>%
    group_by(SampleNo) %>%
    summarise(mean = mean(logprob),
              q1 = quantile(logprob)[2], median = quantile(logprob)[3], q3 = quantile(logprob)[4],
              variance = var(logprob),
              MAD = mad(logprob))
  return(params)
}
get_parameters_single <- function(sample_df){
  vec <- sample_df$logprob
  params <- c(mean = mean(vec),
              q1 = quantile(vec)[2], median = quantile(vec)[3], q3 = quantile(vec)[4],
              variance = var(vec),
              MAD = mad(vec))
  return(params)
}
get_params_from_read_samples_RData <- function(lan){
  rdata_filename <- paste0('samples/', lan,'.10000.samples.bySyl.RData')
  load(rdata_filename)


  samples <- samples %>%
    rename(log2prob = logprob) %>%
    mutate(logprob = -log2prob)

  orig_words_available <- orig_words_available %>%
    rename(log2prob = logprob) %>%
    mutate(logprob = -log2prob)

  params_samples <- get_parameters_multi(samples)
  params_real <- get_parameters_single(orig_words_available)
  params_samples_clean <- get_parameters_multi(subset(samples, seglen > 2))
  params_real_clean <- get_parameters_single(subset(orig_words_available, seglen > 2))
  list(lan, params_samples, params_real, params_samples_clean, params_real_clean)
}

get_params_from_read_samples_bz2 <- function(lan){
  samples_name <- paste0('samples/', lan, '.10000.samples.bySyl.bz2')
  real_lex_name <- paste0('samples/', lan, '.real.lex.bz2')
  len_df_name <- paste0('samples/', lan, '.lengths.df.csv')

  samples <- read_csv(samples_name)
  real_lex <- read_csv(real_lex_name)
  len_usable_df <- read_csv(len_df_name)

  samples <- samples %>%
    rename(log2prob = logprob) %>%
    mutate(logprob = -log2prob)

  real_lex <- real_lex %>%
    rename(log2prob = logprob) %>%
    mutate(logprob = -log2prob)

  params_samples <- get_parameters_multi(samples)
  params_real <- get_parameters_single(real_lex)
  params_samples_clean <- get_parameters_multi(subset(samples, seglen > 2))
  params_real_clean <- get_parameters_single(subset(real_lex, seglen > 2))
  list(lan, params_samples, params_real, params_samples_clean, params_real_clean)
}


params_all_lang_all_samples <- lancodes %>%
  map(get_params_from_read_samples_bz2)



rm(list = objects)
rm(list = c('objects', 'get_parameters_multi', 'get_parameters_single', 'get_params_from_read_samples_RData',
            'lancodes'))

save.image('stats/parameters_10000samples_bySyl_neg_log2.RData')


