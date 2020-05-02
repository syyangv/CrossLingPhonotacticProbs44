rm(list = ls())
library(tidyverse)
library(ISOcodes)
options(stringsAsFactors = F)

args = commandArgs(trailingOnly = TRUE)

source('05_Plotting/plotting_functions.R')

# part 0: sys and input ####
if (length(args) != 3){
  print('Incorrect number of argments. Usage: Rscript --vanilla <script_name>.R en <1/0>')
  quit()
} else{
  LanCode <- args[1]
  sample_num <- args[2]
  n_phone <- as.numeric(args[3])
  sample_num <- as.numeric(sample_num)

  if (sample_num > 150){
    option_plot <- FALSE
  }else{
    option_plot <- TRUE}
  if (sample_num < 1000){
    option_stat <- FALSE
  }else{
    option_stat <- TRUE
  }

  samples_name <- paste0('samples/', LanCode, '.', sample_num, '.samples.bySyl.bz2')
  real_lex_name <- paste0('samples/', LanCode, '.real.lex.bz2')
  len_df_name <- paste0('samples/', LanCode, '.lengths.df.csv')
  plot_writename_CompleteLexicon <- paste0('plots_bit/', LanCode, '.', sample_num, '.CompleteLexicon.pdf')
  cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
}
print(paste('the current language is', LanCode, '\n'))
# get language names that correspond to language codes ----
## Language names that cannot be acquired directly with ISOcodes
lancode_vec <- c('ca', 'el', 'ht', 'ky', 'si', 'ug')
lang_name_vec <- c('Catalan', 'Greek', 'Haitian Creole', 'Kyrgyz', 'Sinhala', 'Uyghur')

lang_ref <- tibble(code = lancode_vec, name = lang_name_vec)

if(LanCode %in% lancode_vec){
  current_lang <- lang_ref[which(lang_ref$code == LanCode),]$name
}else{
  if (str_count(LanCode) == 2){
    current_lang <- ISO_639_2[which(ISO_639_2$Alpha_2 == LanCode),]$Name
  }else{
      current_lang <- ISO_639_3[which(ISO_639_3$Id == LanCode),]$Name
    }
}

samples <- read_csv(samples_name)
real_lex <- read_csv(real_lex_name)
len_usable_df <- read_csv(len_df_name)

samples$seglen <- as.integer(samples$seglen)
real_lex$seglen <- as.integer(real_lex$seglen)

len_usable_df$seglen <- as.integer(len_usable_df$seglen)
len_usable_df$syllen <- as.integer(len_usable_df$syllen)

# change the log_2(prob) to negative
real_lex <- real_lex %>%
  rename(log2prob = logprob) %>%
  mutate(logprob = -log2prob)

samples <- samples %>%
  rename(log2prob = logprob) %>%
  mutate(logprob = -log2prob)

# exclude words where probabilities would be the same due to limitations of the language model
# for a 4-phone model, words with 2 segments or less have the constant probability of log(1/n)
real_lex_excludeConstantSeg <- subset(real_lex, seglen > n_phone - 2)
samples_excludeConstantSeg <- subset(samples, seglen > n_phone - 2)
len_usable_df_excludeConstantSet <- subset(len_usable_df, seglen > n_phone - 2)

# start plotting ####
p_complete <- plot_CompleteLexicon(samples, real_lex, current_lang)
#p_complete

ggsave(plot_writename_CompleteLexicon, plot=p_complete)
#cairo_pdf(plot_writename_CompleteLexicon)
#print(p_complete)
#dev.off()

