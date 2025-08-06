# Basic Analysis and Plots for CWT fMRI Project
# This script creates simple descriptive statistics and basic plots

# Load libraries
library(tidyverse)
library(ggplot2)

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
overall_accuracy <- mean(df$Accuracy == "hit", na.rm = TRUE)
cat("Overall accuracy:", round(overall_accuracy * 100, 2), "%\n")

# Accuracy by condition
accuracy_by_condition <- df %>%
  group_by(TrialValidity2, StimNoise) %>%
  summarise(accuracy = mean(Accuracy == "hit", na.rm = TRUE),
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
  scale_y_continuous(labels = scales::percent)

ggsave("results/figures/accuracy_by_condition.png", p1, width = 8, height = 6)

# 2. Response time distribution
p2 <- ggplot(df, aes(x = ResponseRT)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  labs(title = "Distribution of Response Times",
       x = "Response Time (seconds)", y = "Count") +
  theme_minimal()

ggsave("results/figures/response_time_distribution.png", p2, width = 8, height = 6)

# 3. Confidence distribution
p3 <- ggplot(df, aes(x = RawConfidence)) +
  geom_histogram(bins = 50, fill = "darkgreen", alpha = 0.7) +
  labs(title = "Distribution of Confidence Ratings",
       x = "Confidence", y = "Count") +
  theme_minimal()

ggsave("results/figures/confidence_distribution.png", p3, width = 8, height = 6)

# 4. Accuracy over trials (learning curve)
learning_curve <- df %>%
  group_by(TrialNo) %>%
  summarise(accuracy = mean(Accuracy == "hit", na.rm = TRUE),
            n_trials = n()) %>%
  filter(n_trials >= 5)  # Only show trials with at least 5 observations

p4 <- ggplot(learning_curve, aes(x = TrialNo, y = accuracy)) +
  geom_line(color = "red", size = 1) +
  geom_point(color = "red", alpha = 0.7) +
  labs(title = "Learning Curve: Accuracy Over Trials",
       x = "Trial Number", y = "Accuracy") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent)

ggsave("results/figures/learning_curve.png", p4, width = 10, height = 6)

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
  theme_minimal()

ggsave("results/figures/confidence_by_accuracy.png", p5, width = 8, height = 6)

cat("\nPlots saved to results/figures/\n")
cat("Basic analysis complete!\n") 