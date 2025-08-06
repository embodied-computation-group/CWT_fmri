# GLMM Models for CWT fMRI Study
# MAIN ANALYSIS SCRIPT - Four primary models for predictive processing
# 
# Models:
# 1. Accuracy model (high noise trials only)
# 2. Choice model (high noise trials only) 
# 3. Response time model (all trials)
# 4. Confidence model (all trials)

library(lme4)
library(lmerTest)
library(ordinal)
library(glmmTMB)
library(tidyverse)
library(DHARMa)
library(sjPlot)
library(sjmisc)

# Source data preprocessing
source("code/preprocessing/01_import_and_clean_data.R")

# Data preparation
df$RawConfidence <- df$RawConfidence/100 

df$Accuracy <- factor(df$Accuracy, 
                      levels = c(0, 1), 
                      labels = c("miss", "hit"))

df$TrialValidity2_numeric <- recode(df$TrialValidity2, 
                                    "Valid" = 1, 
                                    "non-predictive" = 0, 
                                    "Invalid" = -1)

# Create SignaledFace variable
df <- df %>%
  mutate(SignaledFace = case_when(
    TrialValidity == "Valid" & CueImg == "0" ~ as.character(FaceEmot),   
    TrialValidity == "Valid" & CueImg == "1" ~ as.character(FaceEmot),   
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Happy" ~ "Angry",  
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Angry" ~ "Happy",  
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Happy" ~ "Angry",  
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Angry" ~ "Happy",  
    TRUE ~ NA_character_  
  ))

df$SignaledFace <- factor(df$SignaledFace, levels = c("Happy", "Angry"))

# Scale TrialsSinceRev within subjects
df <- df %>%
  group_by(SubNo) %>%
  mutate(TrialsSinceRev_scaled = scale(TrialsSinceRev, center = TRUE, scale = TRUE)) %>%
  ungroup()

# Control options for model fitting
control_options <- glmmTMBControl(
  optimizer = optim,
  optArgs = list(method = "BFGS"),
  optCtrl = list(maxit = 10000)
)

# ============================================================================
# MODEL 1: ACCURACY MODEL (dropping low noise trials)
# ============================================================================

cat("Fitting Accuracy Model (dropping low noise trials)...\n")

# Filter out low noise trials for accuracy model
df_accuracy <- df %>% 
  filter(StimNoise == "high noise")

accuracy_model <- glmmTMB(
  Accuracy ~ TrialValidity2_numeric * TrialsSinceRev_scaled * FaceEmot + 
    (1 | SubNo),
  data = df_accuracy,
  family = binomial(link = "logit"),
  control = control_options
)

cat("Accuracy model summary:\n")
summary(accuracy_model)

# Plot accuracy model predictions
accuracy_plot <- plot_model(accuracy_model, 
                           type = "pred", 
                           terms = c("TrialsSinceRev_scaled", "TrialValidity2_numeric", "FaceEmot"),
                           title = "GLMM Accuracy Model: Trial Validity × Trials Since Reversal × Face Emotion") +
  theme_minimal() + 
  theme(panel.background = element_rect(fill = "white"))

print(accuracy_plot)

# Save accuracy plot
ggsave("results/figures/glmm_models/glmm_accuracy_model.png", accuracy_plot, 
       width = 10, height = 8, dpi = 300, bg = "white")

# ============================================================================
# MODEL 2: CHOICE MODEL (low noise trials only)
# ============================================================================

cat("Fitting Choice Model (high noise trials only)...\n")

# Filter for high noise trials only (like accuracy model)
df_choice <- df %>% 
  filter(StimNoise == "high noise")

choice_model <- glmmTMB(
  FaceResponse ~ SignaledFace * FaceEmot * TrialsSinceRev_scaled + 
    (1 | SubNo),
  data = df_choice,
  family = binomial(link = "logit"),
  control = control_options
)

cat("Choice model summary:\n")
summary(choice_model)

# Plot choice model predictions
choice_plot <- plot_model(choice_model, 
                         type = "pred", 
                         terms = c("TrialsSinceRev_scaled", "SignaledFace", "FaceEmot"),
                         title = "GLMM Choice Model: Signaled Face × Face Emotion × Trials Since Reversal") +
  theme_minimal() + 
  theme(panel.background = element_rect(fill = "white")) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(y = "Probability of Happy Response")

print(choice_plot)

# Save choice plot
ggsave("results/figures/glmm_models/glmm_choice_model.png", choice_plot, 
       width = 10, height = 8, dpi = 300, bg = "white")

# ============================================================================
# MODEL 3: RESPONSE TIME MODEL (all trials)
# ============================================================================

cat("Fitting Response Time Model (all trials)...\n")

# Remove NA values for RT model
df_rt <- df %>% 
  na.omit()

rt_model <- glmmTMB(
  ResponseRT ~ StimNoise * TrialValidity2_numeric * TrialsSinceRev_scaled + 
    (1 | SubNo),
  data = df_rt,
  family = Gamma(link = "log"),
  control = control_options
)

cat("Response time model summary:\n")
summary(rt_model)

# Plot RT model predictions
rt_plot <- plot_model(rt_model, 
                      type = "pred", 
                      terms = c("TrialsSinceRev_scaled", "TrialValidity2_numeric", "StimNoise"),
                      title = "GLMM Response Time Model: Trial Validity × Trials Since Reversal × Stimulus Noise") +
  theme_minimal() + 
  theme(panel.background = element_rect(fill = "white"))

print(rt_plot)

# Save RT plot
ggsave("results/figures/glmm_models/glmm_rt_model.png", rt_plot, 
       width = 10, height = 8, dpi = 300, bg = "white")

# ============================================================================
# MODEL 4: CONFIDENCE MODEL (all trials)
# ============================================================================

cat("Fitting Confidence Model (all trials)...\n")

confidence_model <- glmmTMB(
  RawConfidence ~ TrialValidity2_numeric * StimNoise * TrialsSinceRev_scaled + FaceEmot + 
    (1 | SubNo),
  data = df,
  family = ordbeta(),
  start = list(psi = c(0, 1)),
  control = control_options
)

cat("Confidence model summary:\n")
summary(confidence_model)

# Plot confidence model predictions
confidence_plot <- plot_model(confidence_model, 
                             type = "pred", 
                             terms = c("TrialsSinceRev_scaled", "TrialValidity2_numeric", "StimNoise"),
                             title = "GLMM Confidence Model: Trial Validity × Stimulus Noise × Trials Since Reversal") +
  theme_minimal() + 
  theme(panel.background = element_rect(fill = "white"))

print(confidence_plot)

# Save confidence plot
ggsave("results/figures/glmm_models/glmm_confidence_model.png", confidence_plot, 
       width = 10, height = 8, dpi = 300, bg = "white")

# ============================================================================
# SAVE MODELS
# ============================================================================

cat("Saving models...\n")

# Save models
saveRDS(accuracy_model, "results/models/accuracy_model_simple.rds")
saveRDS(choice_model, "results/models/choice_model_simple.rds")
saveRDS(rt_model, "results/models/rt_model_simple.rds")
saveRDS(confidence_model, "results/models/confidence_model_simple.rds")

# Save model summaries to text file for quick inspection
sink("results/models/glmm_model_summaries.txt")
cat("GLMM MODEL SUMMARIES\n")
cat("===================\n\n")

cat("1. ACCURACY MODEL (High Noise Trials Only)\n")
cat("==========================================\n")
print(summary(accuracy_model))
cat("\n\n")

cat("2. CHOICE MODEL (High Noise Trials Only)\n")
cat("========================================\n")
print(summary(choice_model))
cat("\n\n")

cat("3. RESPONSE TIME MODEL (All Trials)\n")
cat("==================================\n")
print(summary(rt_model))
cat("\n\n")

cat("4. CONFIDENCE MODEL (All Trials)\n")
cat("================================\n")
print(summary(confidence_model))
cat("\n\n")

cat("MODEL COMPARISON\n")
cat("===============\n")
cat("Accuracy Model - AIC:", AIC(accuracy_model), "\n")
cat("Choice Model - AIC:", AIC(choice_model), "\n")
cat("RT Model - AIC:", AIC(rt_model), "\n")
cat("Confidence Model - AIC:", AIC(confidence_model), "\n")
sink()

cat("Models saved to results/models/\n")
cat("Model summaries saved to results/models/glmm_model_summaries.txt\n")
cat("Analysis complete!\n")

# ============================================================================
# SCRIPT HISTORY
# ============================================================================
# 
# This script was refactored from 02_run_glmm_models_simple.R to serve as the
# main GLMM analysis script. Previous versions are archived in code/analysis/backup/
# 
# File structure:
# - 02_run_glmm_main.R (current - main analysis script)
# - backup/02_run_glmm_models_original.R (original complex version)
# - backup/02_run_glmm_models_debug.R (debug version)
# - backup/02_run_glmm_models_simple.R (previous working version) 