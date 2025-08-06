# Reversal Learning Analysis for CWT fMRI Project
# Specialized script for reversal learning visualization using established conventions

# Load libraries
library(tidyverse)
library(ggplot2)
library(zoo)

# Load the cleaned data
source("code/preprocessing/01_import_and_clean_data.R")

cat("=== REVERSAL LEARNING ANALYSIS ===\n")

# 1. PERI-REVERSAL LEARNING CURVES
# Standard approach: Show learning around reversal points
cat("Creating peri-reversal learning curves...\n")

# Find reversal points (where TrialsSinceRev = 1)
reversal_points <- df %>%
  filter(TrialsSinceRev == 1) %>%
  group_by(SubNo) %>%
  summarise(reversal_trial = TrialNo) %>%
  ungroup()

# Create peri-reversal windows (e.g., ±20 trials around reversal)
peri_reversal_data <- df %>%
  left_join(reversal_points, by = "SubNo") %>%
  mutate(trials_from_reversal = TrialNo - reversal_trial) %>%
  filter(trials_from_reversal >= -20 & trials_from_reversal <= 20) %>%
  group_by(trials_from_reversal) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    n_trials = n(),
    se_accuracy = sd(Accuracy, na.rm = TRUE) / sqrt(n())
  ) %>%
  filter(n_trials >= 10)  # Only show points with sufficient data

p1 <- ggplot(peri_reversal_data, aes(x = trials_from_reversal, y = accuracy)) +
  geom_line(color = "blue", size = 1.5) +
  geom_point(color = "blue", size = 2) +
  geom_errorbar(aes(ymin = accuracy - se_accuracy, ymax = accuracy + se_accuracy), 
                width = 0.5, color = "blue", alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", size = 1) +
  labs(title = "Peri-Reversal Learning",
       x = "Trials from Reversal", y = "Accuracy",
       subtitle = "Red line = reversal point, Error bars = SEM") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/peri_reversal_learning.png", p1, width = 10, height = 6, bg = "white")

# 2. BLOCK-BASED LEARNING CURVES
# Show learning within stable blocks (before reversals)
cat("Creating block-based learning curves...\n")

# Identify stable learning blocks (e.g., trials 1-20, 21-40, etc.)
block_data <- df %>%
  mutate(block = ceiling(TrialNo / 20)) %>%
  group_by(block, TrialValidity2) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    n_trials = n(),
    mean_rt = mean(ResponseRT, na.rm = TRUE),
    mean_confidence = mean(RawConfidence, na.rm = TRUE)
  ) %>%
  filter(n_trials >= 15)  # Only show blocks with sufficient data

p2 <- ggplot(block_data, aes(x = block, y = accuracy, color = TrialValidity2)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.5) +
  labs(title = "Block-Based Learning by Trial Validity",
       x = "Block (20 trials each)", y = "Accuracy",
       color = "Trial Validity") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  scale_color_brewer(palette = "Set1") +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/block_based_learning.png", p2, width = 12, height = 6, bg = "white")

# 3. REVERSAL ADAPTATION SPEED
# Measure how quickly participants adapt after reversals
cat("Analyzing reversal adaptation speed...\n")

# Calculate adaptation speed (trials to reach 75% accuracy after reversal)
adaptation_speed <- df %>%
  filter(TrialsSinceRev <= 10) %>%  # Focus on early post-reversal trials
  group_by(TrialsSinceRev) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    n_trials = n()
  ) %>%
  filter(n_trials >= 20)

# Find trials to criterion (75% accuracy)
trials_to_criterion <- adaptation_speed %>%
  filter(accuracy >= 0.75) %>%
  slice_min(TrialsSinceRev, n = 1)

cat("Trials to reach 75% accuracy after reversal:", 
    ifelse(nrow(trials_to_criterion) > 0, trials_to_criterion$TrialsSinceRev, "Not reached"), "\n")

p3 <- ggplot(adaptation_speed, aes(x = TrialsSinceRev, y = accuracy)) +
  geom_line(color = "darkgreen", size = 1.5) +
  geom_point(color = "darkgreen", size = 2.5) +
  geom_hline(yintercept = 0.75, linetype = "dashed", color = "red", size = 1) +
  geom_hline(yintercept = 0.5, linetype = "dotted", color = "gray50", size = 0.8) +
  labs(title = "Reversal Adaptation Speed",
       x = "Trials Since Reversal", y = "Accuracy",
       subtitle = "Red line = 75% criterion, Gray line = chance level") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.3, 1)) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/reversal_adaptation_speed.png", p3, width = 10, height = 6, bg = "white")

# 4. LEARNING RATE ANALYSIS
# Exponential decay model for learning rate estimation
cat("Analyzing learning rates...\n")

# Fit exponential decay model to post-reversal learning
post_reversal_data <- df %>%
  filter(TrialsSinceRev <= 15) %>%
  group_by(TrialsSinceRev) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE)) %>%
  filter(!is.na(accuracy))

# Simple exponential fit: accuracy = 1 - (1 - initial) * exp(-rate * trials)
# For visualization, we'll use a moving average approach
learning_rate_data <- post_reversal_data %>%
  mutate(
    accuracy_smooth = zoo::rollmean(accuracy, k = 3, fill = NA, align = "center"),
    learning_rate = c(NA, diff(accuracy_smooth))
  )

p4 <- ggplot(learning_rate_data, aes(x = TrialsSinceRev, y = learning_rate)) +
  geom_line(color = "purple", size = 1.2) +
  geom_point(color = "purple", size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(title = "Learning Rate Over Trials",
       x = "Trials Since Reversal", y = "Learning Rate (ΔAccuracy)",
       subtitle = "Positive = learning, Negative = forgetting") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/learning_rate_analysis.png", p4, width = 10, height = 6, bg = "white")

# 5. INDIVIDUAL DIFFERENCES IN REVERSAL LEARNING
cat("Analyzing individual differences...\n")

# Calculate individual learning metrics
individual_metrics <- df %>%
  group_by(SubNo) %>%
  summarise(
    mean_accuracy = mean(Accuracy, na.rm = TRUE),
    reversal_accuracy = mean(Accuracy[TrialsSinceRev <= 5], na.rm = TRUE),
    stable_accuracy = mean(Accuracy[TrialsSinceRev > 10], na.rm = TRUE),
    adaptation_speed = reversal_accuracy - stable_accuracy,
    n_trials = n()
  ) %>%
  filter(n_trials >= 50)  # Only subjects with sufficient data

# Distribution of individual learning rates
p5 <- ggplot(individual_metrics, aes(x = adaptation_speed)) +
  geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = mean(individual_metrics$adaptation_speed, na.rm = TRUE), 
             color = "red", linetype = "dashed", size = 1) +
  labs(title = "Individual Differences in Reversal Learning",
       x = "Adaptation Speed (Reversal - Stable Accuracy)", y = "Count",
       subtitle = "Red line = mean adaptation speed") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/basic_analysis/individual_differences.png", p5, width = 10, height = 6, bg = "white")

# Print summary statistics
cat("\n=== REVERSAL LEARNING SUMMARY ===\n")
cat("Number of subjects analyzed:", nrow(individual_metrics), "\n")
cat("Mean adaptation speed:", round(mean(individual_metrics$adaptation_speed, na.rm = TRUE), 3), "\n")
cat("SD of adaptation speed:", round(sd(individual_metrics$adaptation_speed, na.rm = TRUE), 3), "\n")
cat("Mean stable accuracy:", round(mean(individual_metrics$stable_accuracy, na.rm = TRUE), 3), "\n")
cat("Mean reversal accuracy:", round(mean(individual_metrics$reversal_accuracy, na.rm = TRUE), 3), "\n")

cat("\nReversal learning analysis complete!\n")
cat("Plots saved to results/figures/\n") 