# Simplified Comprehensive Basic Analysis for CWT fMRI Project
# This script provides a thorough examination without problematic color scales

# Load libraries
library(tidyverse)
library(ggplot2)
library(zoo)  # For moving average calculations
library(gridExtra)  # For arranging multiple plots
library(corrplot)  # For correlation matrices

# Load the cleaned data (run 01_import_and_clean_data.R first)
source("code/preprocessing/01_import_and_clean_data.R")

# Load custom theme
source("code/analysis/theme_nature_neuroscience.R")

cat("=== SIMPLIFIED COMPREHENSIVE BASIC ANALYSIS FOR CWT FMRI PROJECT ===\n")
cat("Analysis started at:", Sys.time(), "\n\n")

# =============================================================================
# 1. BASIC PROPERTIES OF THE DATASET
# =============================================================================

cat("1. BASIC PROPERTIES OF THE DATASET\n")
cat("==================================\n")

# Dataset overview
cat("Dataset Overview:\n")
cat("- Total trials:", nrow(df), "\n")
cat("- Number of subjects:", length(unique(df$SubNo)), "\n")
cat("- Trials per subject:", nrow(df) / length(unique(df$SubNo)), "\n")

# Subject-level summary
subject_summary <- df %>%
  group_by(SubNo) %>%
  summarise(
    n_trials = n(),
    mean_accuracy = mean(Accuracy, na.rm = TRUE),
    mean_rt = mean(ResponseRT, na.rm = TRUE),
    mean_confidence = mean(RawConfidence, na.rm = TRUE),
    sd_rt = sd(ResponseRT, na.rm = TRUE),
    sd_confidence = sd(RawConfidence, na.rm = TRUE)
  )

cat("\nSubject-level statistics:\n")
cat("- Mean accuracy across subjects:", round(mean(subject_summary$mean_accuracy), 3), "\n")
cat("- Mean RT across subjects:", round(mean(subject_summary$mean_rt), 3), "seconds\n")
cat("- Mean confidence across subjects:", round(mean(subject_summary$mean_confidence), 3), "\n")

# =============================================================================
# 2. TASK EFFECTS ON KEY DEPENDENT VARIABLES
# =============================================================================

cat("\n\n2. TASK EFFECTS ON KEY DEPENDENT VARIABLES\n")
cat("===========================================\n")

# 2.1 Stimulus Noise Effects
cat("\n2.1 Stimulus Noise Effects:\n")

noise_effects <- df %>%
  group_by(StimNoise) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    rt = mean(ResponseRT, na.rm = TRUE),
    confidence = mean(RawConfidence, na.rm = TRUE),
    n_trials = n()
  )

cat("Effects of stimulus noise:\n")
print(noise_effects)

# 2.2 Expectation Effects (Trial Validity)
cat("\n2.2 Expectation Effects (Trial Validity):\n")

expectation_effects <- df %>%
  group_by(TrialValidity2) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    rt = mean(ResponseRT, na.rm = TRUE),
    confidence = mean(RawConfidence, na.rm = TRUE),
    n_trials = n()
  )

cat("Effects of trial validity (expectation):\n")
print(expectation_effects)

# 2.3 Learning Effects with Reversal Markers
cat("\n2.3 Learning Effects:\n")

# Learning curve over trials with reversal markers
learning_over_trials <- df %>%
  group_by(TrialNo) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    rt = mean(ResponseRT, na.rm = TRUE),
    confidence = mean(RawConfidence, na.rm = TRUE),
    n_trials = n()
  ) %>%
  filter(n_trials >= 5) %>%
  mutate(
    accuracy_smooth = zoo::rollmean(accuracy, k = 10, fill = NA, align = "center"),
    rt_smooth = zoo::rollmean(rt, k = 10, fill = NA, align = "center"),
    confidence_smooth = zoo::rollmean(confidence, k = 10, fill = NA, align = "center")
  )

# Identify reversal points (where TrialsSinceRev resets to 1)
reversal_points <- df %>%
  filter(TrialsSinceRev == 1) %>%
  group_by(TrialNo) %>%
  summarise(
    n_reversals = n(),
    .groups = 'drop'
  ) %>%
  filter(n_reversals >= 5)  # Only show reversal points with sufficient data

# Plot: Learning curves with reversal markers
p_learning_accuracy <- ggplot(learning_over_trials, aes(x = TrialNo)) +
  geom_line(aes(y = accuracy), color = "gray", alpha = 0.5, size = 0.5) +
  geom_line(aes(y = accuracy_smooth), color = "red", size = 1.5) +
  # Add reversal markers
  geom_vline(data = reversal_points, aes(xintercept = TrialNo), 
             color = "purple", linetype = "dashed", alpha = 0.7, size = 0.8) +
  labs(title = "Learning Curve: Accuracy Over Trials",
       subtitle = "Gray = raw data, Red = 10-trial moving average, Purple lines = reversals",
       x = "Trial Number", y = "Accuracy") +
  scale_y_continuous(labels = scales::percent, limits = c(0.5, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"))

# Learning after reversals - accounting for cue validity and stimulus noise
learning_after_reversals_detailed <- df %>%
  group_by(TrialsSinceRev, TrialValidity2, StimNoise) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    rt = mean(ResponseRT, na.rm = TRUE),
    confidence = mean(RawConfidence, na.rm = TRUE),
    n_trials = n()
  ) %>%
  filter(n_trials >= 10)  # Only show reversal points with sufficient data

# Create improved plots with better visual design and SEM bands
# Calculate SEM for each condition
learning_with_sem <- learning_after_reversals_detailed %>%
  group_by(TrialsSinceRev, TrialValidity2, StimNoise) %>%
  summarise(
    accuracy = mean(accuracy, na.rm = TRUE),
    accuracy_sem = sd(accuracy, na.rm = TRUE) / sqrt(n()),
    confidence = mean(confidence, na.rm = TRUE),
    confidence_sem = sd(confidence, na.rm = TRUE) / sqrt(n()),
    n_trials = n(),
    .groups = 'drop'
  ) %>%
  filter(n_trials >= 5)  # Only show points with sufficient data

# Low noise conditions with improved design
learning_low_noise_sem <- learning_with_sem %>%
  filter(StimNoise == "low noise")

p_reversal_low_noise <- ggplot(learning_low_noise_sem, 
                               aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  # SEM bands
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  # Trend lines with loess smoothing
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  # Individual data points
  geom_point(size = 2.5, alpha = 0.8) +
  # Chance line
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Accuracy Learning After Reversals: Low Noise (Clear Faces)",
       subtitle = "Valid cues should increase accuracy, Invalid cues should decrease it\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# High noise conditions with improved design
learning_high_noise_sem <- learning_with_sem %>%
  filter(StimNoise == "high noise")

p_reversal_high_noise <- ggplot(learning_high_noise_sem, 
                                aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  # SEM bands
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  # Trend lines with loess smoothing
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  # Individual data points
  geom_point(size = 2.5, alpha = 0.8) +
  # Chance line
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Accuracy Learning After Reversals: High Noise (Ambiguous Faces)",
       subtitle = "Stronger effects expected - cues should matter more for ambiguous faces\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# Combine the improved plots
p_reversal_learning_combined <- grid.arrange(p_reversal_low_noise, p_reversal_high_noise, ncol = 2)

ggsave("results/figures/basic_analysis/learning_after_reversals_simple.png", p_reversal_learning_combined, 
       width = 16, height = 6, bg = "white")

# Additional sophisticated reversal analysis
cat("\nDetailed Reversal Learning Analysis:\n")

# Analyze learning effects by condition
reversal_learning_summary <- learning_after_reversals_detailed %>%
  group_by(TrialValidity2, StimNoise) %>%
  summarise(
    early_accuracy = mean(accuracy[TrialsSinceRev <= 5], na.rm = TRUE),
    late_accuracy = mean(accuracy[TrialsSinceRev > 10], na.rm = TRUE),
    learning_effect = late_accuracy - early_accuracy,
    early_confidence = mean(confidence[TrialsSinceRev <= 5], na.rm = TRUE),
    late_confidence = mean(confidence[TrialsSinceRev > 10], na.rm = TRUE),
    confidence_learning = late_confidence - early_confidence,
    .groups = 'drop'
  )

cat("Learning effects by condition (late - early performance):\n")
print(reversal_learning_summary)

cat("\nReversal Analysis:\n")
cat("Number of reversal points identified:", nrow(reversal_points), "\n")
if(nrow(reversal_points) > 0) {
  cat("Reversal trials:", paste(reversal_points$TrialNo, collapse = ", "), "\n")
}

cat("\nAnalysis completed at:", Sys.time(), "\n") 