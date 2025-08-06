# Basic Analysis and Plots for CWT fMRI Project
# This script creates simple descriptive statistics and basic plots

# Load libraries
library(tidyverse)
library(ggplot2)
library(zoo)  # For moving average calculations

# Load the cleaned data (run 01_import_and_clean_data.R first)
source("code/preprocessing/01_import_and_clean_data.R")

# Basic descriptive statistics
cat("=== BASIC DESCRIPTIVE STATISTICS ===\n")

# Number of subjects
n_subjects <- length(unique(df$SubNo))
cat("Number of subjects:", n_subjects, "\n")

# Number of trials per subject
trials_per_subject <- df %>%
  group_by(SubNo) %>%
  summarise(n_trials = n()) %>%
  summarise(mean_trials = mean(n_trials),
            min_trials = min(n_trials),
            max_trials = max(n_trials))

cat("Trials per subject - Mean:", trials_per_subject$mean_trials, 
    "Min:", trials_per_subject$min_trials, 
    "Max:", trials_per_subject$max_trials, "\n")

# Overall accuracy
overall_accuracy <- mean(df$Accuracy, na.rm = TRUE)
cat("Overall accuracy:", round(overall_accuracy * 100, 2), "%\n")

# Accuracy by condition
accuracy_by_condition <- df %>%
  group_by(TrialValidity2, StimNoise) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n()) %>%
  arrange(TrialValidity2, StimNoise)

cat("\nAccuracy by condition:\n")
print(accuracy_by_condition)

# Mean response time
mean_rt <- mean(df$ResponseRT, na.rm = TRUE)
cat("\nMean response time:", round(mean_rt, 3), "seconds\n")

# Mean confidence
mean_confidence <- mean(df$RawConfidence, na.rm = TRUE)
cat("Mean confidence:", round(mean_confidence, 3), "\n")

# Create basic plots
cat("\n=== CREATING BASIC PLOTS ===\n")

# 1. Accuracy by condition
p1 <- ggplot(accuracy_by_condition, aes(x = TrialValidity2, y = accuracy, fill = StimNoise)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Accuracy by Trial Validity and Stimulus Noise",
       x = "Trial Validity", y = "Accuracy", fill = "Stimulus Noise") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/basic_analysis/accuracy_by_condition.png", p1, width = 8, height = 6, bg = "white")

# 2. Response time distribution
p2 <- ggplot(df, aes(x = ResponseRT)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  labs(title = "Distribution of Response Times",
       x = "Response Time (seconds)", y = "Count") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/basic_analysis/response_time_distribution.png", p2, width = 8, height = 6, bg = "white")

# 3. Confidence distribution
p3 <- ggplot(df, aes(x = RawConfidence)) +
  geom_histogram(bins = 50, fill = "darkgreen", alpha = 0.7) +
  labs(title = "Distribution of Confidence Ratings",
       x = "Confidence", y = "Count") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/confidence_analysis/confidence_distribution.png", p3, width = 8, height = 6, bg = "white")

# 4. Improved learning curves
# 4a. Smoothed learning curve with moving average
learning_curve_smooth <- df %>%
  group_by(TrialNo) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n()) %>%
  filter(n_trials >= 5) %>%
  mutate(accuracy_smooth = zoo::rollmean(accuracy, k = 10, fill = NA, align = "center"))

p4a <- ggplot(learning_curve_smooth, aes(x = TrialNo)) +
  geom_line(aes(y = accuracy), color = "gray", alpha = 0.5, size = 0.5) +
  geom_line(aes(y = accuracy_smooth), color = "red", size = 1.5) +
  labs(title = "Learning Curve: Accuracy Over Trials (Smoothed)",
       x = "Trial Number", y = "Accuracy",
       subtitle = "Gray line = raw data, Red line = 10-trial moving average") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.5, 1)) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/learning_curve_smoothed.png", p4a, width = 12, height = 6, bg = "white")

# 4b. Learning by trials since reversal (more meaningful for this task)
learning_by_reversal_detailed <- df %>%
  group_by(TrialsSinceRev) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n(),
            mean_confidence = mean(RawConfidence, na.rm = TRUE)) %>%
  filter(n_trials >= 20)  # Only show reversal points with sufficient data

p4b <- ggplot(learning_by_reversal_detailed, aes(x = TrialsSinceRev, y = accuracy)) +
  geom_line(color = "blue", size = 1.5) +
  geom_point(color = "blue", alpha = 0.7, size = 2) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7) +
  labs(title = "Learning After Probability Reversals",
       x = "Trials Since Reversal", y = "Accuracy",
       subtitle = "Shows adaptation to changing cue-face contingencies (dashed line = chance)") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/learning_after_reversals_detailed.png", p4b, width = 10, height = 6, bg = "white")

# 4c. Learning by condition and trials since reversal
learning_by_condition <- df %>%
  group_by(TrialValidity2, TrialsSinceRev) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n()) %>%
  filter(n_trials >= 10)  # Only show points with sufficient data

p4c <- ggplot(learning_by_condition, aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  geom_line(size = 1) +
  geom_point(alpha = 0.7, size = 1.5) +
  labs(title = "Learning by Trial Validity",
       x = "Trials Since Reversal", y = "Accuracy",
       color = "Trial Validity",
       subtitle = "Different learning patterns for valid, invalid, and non-predictive trials") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  scale_color_brewer(palette = "Set1") +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/learning_by_condition.png", p4c, width = 12, height = 6, bg = "white")

# 5. Confidence by accuracy
confidence_by_accuracy <- df %>%
  group_by(Accuracy) %>%
  summarise(mean_confidence = mean(RawConfidence, na.rm = TRUE),
            se_confidence = sd(RawConfidence, na.rm = TRUE) / sqrt(n()))

p5 <- ggplot(confidence_by_accuracy, aes(x = Accuracy, y = mean_confidence)) +
  geom_bar(stat = "identity", fill = "orange", alpha = 0.7) +
  geom_errorbar(aes(ymin = mean_confidence - se_confidence, 
                    ymax = mean_confidence + se_confidence), 
                width = 0.2) +
  labs(title = "Confidence by Accuracy",
       x = "Accuracy", y = "Mean Confidence") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/confidence_analysis/confidence_by_accuracy.png", p5, width = 8, height = 6, bg = "white")

# 6. Task-specific analyses based on experimental design
cat("\n=== TASK-SPECIFIC ANALYSES ===\n")

# Accuracy by cue validity and stimulus noise
accuracy_by_condition_detailed <- df %>%
  group_by(TrialValidity2, StimNoise) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n(),
            mean_rt = mean(ResponseRT, na.rm = TRUE),
            mean_confidence = mean(RawConfidence, na.rm = TRUE)) %>%
  arrange(TrialValidity2, StimNoise)

cat("Detailed accuracy by condition:\n")
print(accuracy_by_condition_detailed)

# Learning over trials since reversal
learning_by_reversal <- df %>%
  group_by(TrialsSinceRev) %>%
  summarise(accuracy = mean(Accuracy, na.rm = TRUE),
            n_trials = n()) %>%
  filter(n_trials >= 10)  # Only show reversal points with sufficient data

p6 <- ggplot(learning_by_reversal, aes(x = TrialsSinceRev, y = accuracy)) +
  geom_line(color = "purple", size = 1) +
  geom_point(color = "purple", alpha = 0.7) +
  labs(title = "Learning After Probability Reversals",
       x = "Trials Since Reversal", y = "Accuracy",
       subtitle = "Shows adaptation to changing cue-face contingencies") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/learning_curves/learning_after_reversals.png", p6, width = 10, height = 6, bg = "white")

# Confidence by stimulus noise
confidence_by_noise <- df %>%
  group_by(StimNoise) %>%
  summarise(mean_confidence = mean(RawConfidence, na.rm = TRUE),
            se_confidence = sd(RawConfidence, na.rm = TRUE) / sqrt(n()))

p7 <- ggplot(confidence_by_noise, aes(x = StimNoise, y = mean_confidence)) +
  geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
  geom_errorbar(aes(ymin = mean_confidence - se_confidence, 
                    ymax = mean_confidence + se_confidence), 
                width = 0.2) +
  labs(title = "Confidence by Stimulus Noise",
       x = "Stimulus Noise", y = "Mean Confidence",
       subtitle = "High noise = ambiguous faces, Low noise = clear faces") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white"))

ggsave("results/figures/confidence_analysis/confidence_by_noise.png", p7, width = 8, height = 6, bg = "white")

cat("\nPlots saved to results/figures/ subdirectories:\n")
cat("- Basic analysis plots: results/figures/basic_analysis/\n")
cat("- Learning curves: results/figures/learning_curves/\n")
cat("- Confidence analysis: results/figures/confidence_analysis/\n")
cat("Basic analysis complete!\n") 