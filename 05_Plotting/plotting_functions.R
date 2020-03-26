library(tidyverse)
library(extrafont)
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

alpha_set_samples <- 0.2
line_size_set_samples <- 0.1
line_size_set_training <- 0.8

# complete lexicon ####
plot_CompleteLexicon <- function(tibble_samples, tibble_training, lang){
  p <- ggplot(data = tibble_samples, aes(x = logprob)) +
    geom_line(stat = 'density',
              aes(group = SampleNo, color = 'samples'),
              alpha = alpha_set_samples, size = line_size_set_samples) +
    geom_line(data = tibble_training, stat = 'density',
              aes(x = logprob, color = 'real'),
              size = line_size_set_training)
  p <- p + scale_color_manual(paste(lang, 'lexicons'),
                              values = cbPalette[c(4,8)],
                              labels = c('real', 'samples')) +
    labs(x = paste('Log probabilities based on words in that are above the 5000th highest frequency in', lang),
         y = 'Density',
         title = '') +
    theme_minimal() +
    theme(text = element_text(family = 'Times New Roman', size = 10),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(color = 'black'),
          plot.title = element_text(margin = margin(b = -20))
          )
  return(p)
}

# plot by the number of syllables ####
#tibble_samples <- samples
#tibble_training <- real_lex
#lang <- current_lang
#syl_seg_combinations <- len_usable_df
#filter_count <- 50


plot_PerSyl <- function(tibble_samples, tibble_training,
                        lang, syl_seg_combinations, filter_count = 50,
                        exclude_1 = FALSE){
  # plot each syl length together
  # @syl_seg_combinations - tibble for counts for seg and syl length
  # @filter_count - the number of word types for each seglen to accept to be plotted

  ## plot only length of syllables that have more than certain number of words ###
  count_BySyl <- syl_seg_combinations %>% group_by(syllen) %>%
    summarise(n = sum(count), segn = n()) %>%
    mutate(include = if_else(filter_count*segn < n, 1, 0))
  if (exclude_1){
    count_BySyl$include[count_BySyl$syllen == 1] <- 0
  }
  # exclude syl length if the mean count of words by seg length does not surpass the filter_count
  min_syl <- min(subset(count_BySyl, include == 1)$syllen)
  # starting point for syl length for this language

  samples_include_BySyl <- tibble_samples %>%
    inner_join(count_BySyl %>% select(syllen, include))
  training_include_BySyl <- tibble_training %>%
    inner_join(count_BySyl %>% select(syllen, include, n))
  samples_include_BySyl <- subset(samples_include_BySyl, include == 1) %>% select(-include)
  training_include_BySyl <- subset(training_include_BySyl, include == 1) %>% select(-include)

  #### plotting ####
  p <- ggplot(data = samples_include_BySyl, aes(x = logprob)) +
    geom_line(stat = 'density', aes(group = SampleNo, color = 'samples'),
              alpha = alpha_set_samples, size = line_size_set_samples) +
    geom_line(stat = 'density', data = training_include_BySyl,
              aes(x = logprob, color = 'real'),
              size = line_size_set_training)

  p <- p + scale_color_manual(paste(lang, 'lexicons'),
                              values = cbPalette[c(4,8)],
                              labels = c('real', 'samples')) +
    labs(x = paste('Log probabilities based on words in that are above the 5000th highest frequency in', lang),
         y = 'Density',
         title = '') +
    theme_minimal() +
    theme(text = element_text(family = 'Times New Roman', size = 10),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(color = 'black'),
          plot.title = element_text(margin = margin(b = -20))
          )
  name_syl_labs <- function(string){
    paste('number of syllables =', string)
  }
  p <- p + facet_wrap(~ syllen, labeller = labeller(syllen = name_syl_labs)) +
    theme(strip.background = element_rect(fill = alpha(cbPalette[6], 0.3),
                                          color = 'white'),
          strip.text = element_text(face = 'bold'))

  # add number of word types to each panel
  training_count <- count_BySyl %>%
    filter(include == 1) %>%
    select(syllen, n)
  mean.x = (max(tibble_samples$logprob) + min(tibble_samples$logprob))/2
  max.y = max(density(subset(tibble_training, syllen == min_syl)$logprob)$y)

  p <- p + geom_text(data = training_count,
                     aes(x = mean.x, y = max.y,
                         label = paste('number of word types = ', n)),
                     size = 2.5, family = 'Times New Roman')
  return(p)
}

# plot by the number of syllables and segments####
#
#tibble_samples <- samples
#tibble_training <- real_lex
#lang <- current_lang
#syl_seg_combinations <- len_usable_df
#filter_number <- 50

plot_PerSegPerSyl <- function(tibble_samples, tibble_training, lang,
                              syl_seg_combinations, filter_number = 50,
                              exclude_1 = FALSE){
  #filter block with too few word types
  count_BySylSeg <- syl_seg_combinations %>% mutate(include = ifelse(filter_number < count, 1, 0))
  if (exclude_1){
    count_BySylSeg$include[count_BySylSeg$syllen == 1] <- 0
  }
  samples_include_BySylSeg <- tibble_samples %>% inner_join(count_BySylSeg %>% select(-count))
  training_include_BySylSeg <- tibble_training %>% inner_join(count_BySylSeg %>% select(-count))
  samples_include_BySylSeg <- subset(samples_include_BySylSeg, include == 1) %>% select(-include)
  training_include_BySylSeg <- subset(training_include_BySylSeg, include == 1) %>% select(-include)

  p <- ggplot(data = samples_include_BySylSeg, aes(x = logprob)) +
    geom_line(stat = 'density', aes(group = SampleNo, color = 'samples'), alpha = alpha_set_samples, size = line_size_set_samples) +
    geom_line(stat = 'density', data = training_include_BySylSeg, aes(x = logprob, color = 'real'), size = line_size_set_training)
  p <- p + scale_color_manual(paste0(lang, ' lexicons'),
                              values = cbPalette[c(4,8)],
                              labels = c('real', 'samples')) +
    xlab(paste('Log probabilities based on words in that are above the 5000th highest frequency in', lang)) +
    ylab('Density') +
    theme_minimal() +
    theme(text = element_text(family = 'Times New Roman', size = 10),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(color = 'black'),
          plot.title = element_text(margin = margin(b = -20))
    )

  name_syl_labs <- function(string){
    paste('#syllables =', string)
  }
  name_seg_labs <- function(string){
    paste(string, 'segs')
  }
  p <- p + facet_grid(seglen ~ syllen, labeller = labeller(syllen = name_syl_labs, seglen = name_seg_labs), scales = 'free_y') +
    theme(strip.background = element_rect(fill = alpha(cbPalette[6],.3), color = 'white'), strip.text = element_text(face = 'bold'))

  training_count <- subset(count_BySylSeg, include == 1) %>% select(syllen, seglen, count)
  mean.x <- (max(tibble_samples$logprob) + min(tibble_samples$logprob))/2
  max.y <- do.call(rbind, lapply(unique(training_include_BySylSeg$seglen), function(segx){
    l <- max(density(subset(training_include_BySylSeg, seglen == segx)$logprob)$y)
    c(seglen = segx, max = l)
  }))
  training_count <- training_count %>% inner_join(as_tibble(max.y))

  p <- p + geom_text(data = training_count,
                     aes(x = mean.x, y = max, label = paste('#word types = ', count)),
                     size = 2.5, family = 'Times New Roman',
                     hjust = 0.6)

  return(p)
  }






