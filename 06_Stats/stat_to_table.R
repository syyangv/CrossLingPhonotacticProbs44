rm(list = ls())
library(tidyverse)
options(stringsAsFactors = F)

#setwd('~/Dropbox (Brown)/CrossLing_Crubadan/')

# define functions ----
get_interval_from_ecdf <- function(list_of_ecdfs, vec_real_lex, alpha = 0.05){
  # for each language, output the named vector of CI, max, min and real value for each parameter
  map2(list_of_ecdfs, vec_real_lex,
       ~c(CI_l = quantile(.x, alpha/2),
          CI_u = quantile(.x, 1-alpha/2),
          max = quantile(.x, 1),
          min = quantile(.x, 0),
          real_value = .y,
          real_percentile = .x(.y)
       )
  )
}

summarize_params_in_each_language <- function(intervals_one_language, values_parameters, names_parameters){
  # for each language,
  # output the df with each parameter as row and
  # each column as a spec of the parameter
  stack(intervals_one_language) %>%
    add_column(
      chosen_value = rep(values_parameters, length(names_parameters))
    ) %>%
    spread(key = chosen_value, value = values) %>%
    rename(parameter = ind)
}

# choose the sample to process ----
#negative log2
load('stats/parameters_10000samples_bySyl_neg_log2.RData')
params_samples_neg <- params_all_lang_all_samples
#load('stats/parameters_10000samples_bySyl_pos_log2.RData')
#params_samples_pos <- params_all_lang_all_samples
# extract samples and real values ----
# Fhat from samples
lang_list_neg <- params_samples_neg %>%
  map(1)
#lang_list_pos <- params_samples_pos %>%
#  map(1)

Fhat_samples_neg <- params_samples_neg %>%
  map(2) %>%
  map(~list(
    "mean" = ecdf(.x$mean),
    "q1" = ecdf(.x$q1),
    "median" = ecdf(.x$median),
    "q3" = ecdf(.x$q3),
    "variance" = ecdf(.x$variance),
    "MAD" = ecdf(.x$MAD)
  ))
real_vec_neg <- params_samples_neg %>%
  map(3)

#Fhat_samples_pos <- params_samples_pos %>%
#  map(2) %>%
#  map(~list(
#    "mean" = ecdf(.x$mean),
#    "q1" = ecdf(.x$q1),
#    "median" = ecdf(.x$median),
#    "q3" = ecdf(.x$q3),
#    "variance" = ecdf(.x$variance),
#    "MAD" = ecdf(.x$MAD)
#  ))
#real_vec_pos <- params_samples_pos %>%
#  map(3)

# Fhat from cleaned samples
Fhat_samples_clean_neg <- params_samples_neg %>%
  map(4) %>%
  map(~list(
    "mean" = ecdf(.x$mean),
    "q1" = ecdf(.x$q1),
    "median" = ecdf(.x$median),
    "q3" = ecdf(.x$q3),
    "variance" = ecdf(.x$variance),
    "MAD" = ecdf(.x$MAD)
  ))
real_vec_clean_neg <- params_samples_neg %>%
  map(5)

# Fhat_samples_clean_pos <- params_samples_pos %>%
#   map(4) %>%
#   map(~list(
#     "mean" = ecdf(.x$mean),
#     "q1" = ecdf(.x$q1),
#     "median" = ecdf(.x$median),
#     "q3" = ecdf(.x$q3),
#     "variance" = ecdf(.x$variance),
#     "MAD" = ecdf(.x$MAD)
#   ))
# real_vec_clean_pos <- params_samples_pos %>%
#   map(5)



# find 2.5% - 97.5% interval for each parameter ----
#test <- Fhat_samples[[1]]
#test_real_vec <- real_vec[[1]]
samples_interval_neg <- map2(Fhat_samples_neg, real_vec_neg, ~get_interval_from_ecdf(.x, .y))
samples_clean_interval_neg <- map2(Fhat_samples_clean_neg, real_vec_clean_neg, ~get_interval_from_ecdf(.x, .y))

names_parameters_neg <- names(real_vec_neg[[1]]) %>% str_remove_all("\\..*$")
values_parameters_neg <- names(samples_interval_neg[[1]][[1]]) %>% str_remove_all("\\..*$")
#
# samples_interval_pos <- map2(Fhat_samples_pos, real_vec_pos, ~get_interval_from_ecdf(.x, .y))
# samples_clean_interval_pos <- map2(Fhat_samples_clean_pos, real_vec_clean_pos, ~get_interval_from_ecdf(.x, .y))
#
# names_parameters_pos <- names(real_vec_pos[[1]]) %>% str_remove_all("\\..*$")
# values_parameters_pos <- names(samples_interval_pos[[1]][[1]]) %>% str_remove_all("\\..*$")

# put everything in the same df ----
#test <- samples_interval[[1]]
summary_languages_neg <- samples_interval_neg %>%
  map(
    ~summarize_params_in_each_language(
      .x,
      values_parameters = values_parameters_neg,
      names_parameters = names_parameters_neg
      )
    ) %>%
  map2(lang_list_neg, ~.x %>% add_column(lang = .y)) %>%
  bind_rows() %>%
  as_tibble() %>%
  mutate(parameter = as.character(parameter))
#
# summary_languages_pos <- samples_interval_pos %>%
#   map(
#     ~summarize_params_in_each_language(
#       .x,
#       values_parameters = values_parameters_pos,
#       names_parameters = names_parameters_pos)) %>%
#   map2(lang_list_pos, ~.x %>% add_column(lang = .y)) %>%
#   bind_rows() %>%
#   as_tibble() %>%
#   mutate(parameter = as.character(parameter))

summary_languages_neg_clean <- samples_clean_interval_neg %>%
  map(
    ~summarize_params_in_each_language(
      .x,
      values_parameters = values_parameters_neg,
      names_parameters = names_parameters_neg
    )
  ) %>%
  map2(lang_list_neg, ~.x %>% add_column(lang = .y)) %>%
  bind_rows() %>%
  as_tibble() %>%
  mutate(parameter = as.character(parameter))
#
# summary_languages_pos_clean <- samples_clean_interval_pos %>%
#   map(
#     ~summarize_params_in_each_language(
#       .x,
#       values_parameters = values_parameters_pos,
#       names_parameters = names_parameters_pos)) %>%
#   map2(lang_list_pos, ~.x %>% add_column(lang = .y)) %>%
#   bind_rows() %>%
#   as_tibble() %>%
#   mutate(parameter = as.character(parameter))



save(summary_languages_neg, summary_languages_neg_clean,
     file = 'stats/params_table_bySyl_neg_log2_10000.RData')
#save(summary_languages_pos, summary_languages_pos_clean,
#     file = 'stats/params_table_bySyl_pos_log2.RData')
save.image()



