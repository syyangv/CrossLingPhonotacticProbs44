rm(list = ls())
library(tidyverse)
options(stringsAsFactors = F)
library(extrafont)
library(ISOcodes)
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")


setwd('~/Dropbox (Brown)/CrossLing_Crubadan_dirichlet_mono_di/')

#
load('stats/params_table_bySyl_neg_log2.RData')
load('stats/parameters_100samples_bySyl_neg_log2.RData')

#1. get all medians from samples for each language ----
summary_medians_22 <- subset(summary_languages_neg, parameter == 'median')

lang_list <- params_all_lang_all_samples %>% map(1)

medians_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$median)
medians_22_all_tb <- tibble(median = unlist(medians_22_all),
                            lancode = rep(unlist(lang_list), each = 100))

medians_df <- medians_22_all_tb %>%
  left_join(summary_medians_22, by = c("lancode" = "lang")) %>%
  select(median, lancode, CI_l, CI_u, real_value)

medians_df <- subset(medians_df, lancode != 'om')

#2. get all means from samples for each language ----
summary_means_22 <- subset(summary_languages_neg, parameter == 'mean')

means_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$mean)
means_22_all_tb <- tibble(mean = unlist(means_22_all),
                          lancode = rep(unlist(lang_list), each = 100))

means_df <- means_22_all_tb %>%
  left_join(summary_means_22, by = c("lancode" = "lang")) %>%
  select(mean, lancode, CI_l, CI_u, real_value)

means_df <- subset(means_df, lancode != 'om')

#3. q1 ----
summary_q1_22 <- subset(summary_languages_neg, parameter == 'q1')

q1_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$q1)
q1_22_all_tb <- tibble(q1 = unlist(q1_22_all),
                       lancode = rep(unlist(lang_list), each = 100))

q1_df <- q1_22_all_tb %>%
  left_join(summary_q1_22, by = c("lancode" = "lang")) %>%
  select(q1, lancode, CI_l, CI_u, real_value)

q1_df <- subset(q1_df, lancode != 'om')
#4. variance ----
summary_variance_22 <- subset(summary_languages_neg, parameter == 'variance')

variance_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$variance)
variance_22_all_tb <- tibble(variance = unlist(variance_22_all),
                       lancode = rep(unlist(lang_list), each = 100))

variance_df <- variance_22_all_tb %>%
  left_join(summary_variance_22, by = c("lancode" = "lang")) %>%
  select(variance, lancode, CI_l, CI_u, real_value)

variance_df <- subset(variance_df, lancode != 'om')

#5. q3 ----
summary_q3_22 <- subset(summary_languages_neg, parameter == 'q3')

q3_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$q3)
q3_22_all_tb <- tibble(q3 = unlist(q3_22_all),
                       lancode = rep(unlist(lang_list), each = 100))

q3_df <- q3_22_all_tb %>%
  left_join(summary_q3_22, by = c("lancode" = "lang")) %>%
  select(q3, lancode, CI_l, CI_u, real_value)

q3_df <- subset(q3_df, lancode != 'om')
#6. MAD ----
summary_MAD_22 <- subset(summary_languages_neg, parameter == 'MAD')

MAD_22_all <- params_all_lang_all_samples %>% map(2) %>% map(~.x$MAD)
MAD_22_all_tb <- tibble(MAD = unlist(MAD_22_all),
                             lancode = rep(unlist(lang_list), each = 100))

MAD_df <- MAD_22_all_tb %>%
  left_join(summary_MAD_22, by = c("lancode" = "lang")) %>%
  select(MAD, lancode, CI_l, CI_u, real_value)

MAD_df <- subset(MAD_df, lancode != 'om')

### snippet for getting language names----
lang_ref <- tibble(lancode = unique(medians_df$lancode),
                   name = c('Azerbaijani', 'Bulgarian', 'Catalan', 'Chuvash',
                            'Haitian Creole', 'Hungarian', 'Armenian', 'Javanese',
                            'Georgian', 'Kannada', 'Korean', 'Kirghiz',
                            'Maltese', 'Sinhala', 'Slovak', 'Albanian',
                            'Tajik', 'Turkish', 'Tatar', 'Ukrainian',
                            'Wolof', 'Zaza'))
#####
medians_df <- medians_df %>% left_join(lang_ref, by = 'lancode')
means_df <- means_df %>% left_join(lang_ref, by = 'lancode')
q1_df <- q1_df %>% left_join(lang_ref, by = 'lancode')
q3_df <- q3_df %>% left_join(lang_ref, by = 'lancode')
variance_df <- variance_df %>% left_join(lang_ref, by = 'lancode')
MAD_df <- MAD_df %>% left_join(lang_ref, by = 'lancode')
library(lemon)
p_median <- ggplot(medians_df, aes(x = median)) +
  geom_histogram(binwidth = 0.05, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 12),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold')) +
  xlab("Median of phonotactic probabilities (in bits)") +
  ylab("Count")

# free_scale 0.01 facet_wrap(scale = "free")
# non_free_scale 0.05
# free_scale 0.015 facet_wrap(scale = "free_x")

#ggsave("stats/medians_distribution_100_samples_free_x.pdf",
#       plot=p_median,
#       width = 8.5, height = 11, units = "in")

p_median_lemon <- ggplot(medians_df, aes(x = median)) +
  geom_histogram(binwidth = 0.05, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 12),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'red'),
        axis.line.y = element_line(color = 'black'),
        axis.line.x = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_rep_wrap(~name, nrow = 6, scales = 'free_x', repeat.tick.labels = ) +
  coord_capped_cart(bottom='both', xlim = c(12,14)) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold')) +
  xlab("Median of phonotactic probabilities (in bits)") +
  ylab("Count")

# free_scale 0.03 facet_wrap(scale = "free")
# non_free_scale 0.05
# free_scale 0.015 facet_wrap(scale = "free_x")

ggsave("stats/medians_distribution_100_samples_label_with_axis.pdf",
       plot=p_median_lemon,
       width = 8.5, height = 11, units = "in")

p_mean <- ggplot(means_df, aes(x = mean)) +
  geom_histogram(binwidth = 0.035, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 10),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold'))

ggsave("stats/means_distribution_100_samples.pdf", plot=p_mean)

p_q1 <- ggplot(q1_df, aes(x = q1)) +
  geom_histogram(binwidth = 0.015, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 10),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold'))
ggsave("stats/q1_distribution_100_samples.pdf", plot=p_q1)

p_var <- ggplot(variance_df, aes(x = variance)) +
  geom_histogram(binwidth = 0.055, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 10),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold'))
ggsave("stats/var_distribution_100_samples.pdf", plot=p_var)

p_q3 <- ggplot(q3_df, aes(x = q3)) +
  geom_histogram(binwidth = 0.045, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 10),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold'))

ggsave("stats/q3_distribution_100_samples.pdf", plot=p_q3)


p_MAD <- ggplot(MAD_df, aes(x = MAD)) +
  geom_histogram(binwidth = 0.035, color = "white", size = 0.0005, fill = cbPalette[8]) +
  geom_vline(aes(xintercept = CI_l), linetype = "dashed", size = 0.2) +
  geom_vline(aes(xintercept = CI_u), linetype = "dashed", size = 0.2) +
  geom_point(aes(x = real_value, y = 5), color = cbPalette[4], size = 1.5) +
  theme_minimal() +
  theme(text = element_text(family = 'Times New Roman', size = 10),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(color = 'black'),
        plot.title = element_text(margin = margin(b = -20))) +
  facet_wrap(~name, nrow = 6) +
  theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                        color = 'white'),
        strip.text = element_text(face = 'bold'))
ggsave("stats/MAD_distribution_100_samples.pdf", plot=p_MAD)

