library("afex")
library("emmeans")
library("dplyr")
library("ggplot2")
library("cowplot")
library("ggbeeswarm")
library("tidyverse")
source("getdata.R")
## accuracy
aov_data <- df %>% 
  select(c("TrialValidity2", "StimNoise", "Accuracy"), "SubNo") %>% 
  na.omit()

# fit anova 
e1_anova <- aov_ez(
  id = "SubNo", 
  dv = "Accuracy", 
  data = aov_data,
  within = c("TrialValidity2", "StimNoise"), 
  na.RM = TRUE,
  fun_aggregate = mean
)


nice(e1_anova) # pvalues


# plot
afex_plot(e1_anova, "TrialValidity2","StimNoise", error = "within", 
          data_geom = geom_quasirandom, data_alpha = 0.3)+
  labs(y = "Mean Accuracy", x = "Cue Validity") +
  theme_classic()

## rt
aov_data <- df %>% 
  select(c("TrialValidity2", "StimNoise", "ResponseRT"), "SubNo") %>% 
  na.omit()

# fit anova 
e1_anova <- aov_ez(
  id = "SubNo", 
  dv = "ResponseRT", 
  data = aov_data,
  within = c("TrialValidity2", "StimNoise"), 
  na.RM = TRUE,
  fun_aggregate = median
)


nice(e1_anova) # pvalues


# plot
afex_plot(e1_anova, "TrialValidity2","StimNoise", error = "within", 
          data_geom = ggpol::geom_boxjitter, data_alpha = 0.3)+
  labs(y = "Median RT", x = "Cue Validity") +
  theme_classic()

## rt
aov_data <- df %>% 
  select(c("TrialValidity2", "StimNoise", "FaceEmot","ResponseRT"), "SubNo") %>% 
  na.omit()

# fit anova 
e1_anova <- aov_ez(
  id = "SubNo", 
  dv = "ResponseRT", 
  data = aov_data,
  within = c("TrialValidity2", "StimNoise", "FaceEmot"), 
  na.RM = TRUE,
  fun_aggregate = mean
)


nice(e1_anova) # pvalues


# plot
afex_plot(e1_anova, "TrialValidity2","StimNoise","FaceEmot", error = "within", 
          data_geom = ggpol::geom_boxjitter, data_alpha = 0.3)+
  labs(y = "Confidence", x = "Cue Validity") +
  theme_classic()