# Corrected Comprehensive Basic Analysis for CWT fMRI Project
# This script accounts for counterbalanced orders and jitter in reversal timing

# Load libraries
library(tidyverse)
library(ggplot2)
library(zoo)  # For moving average calculations
library(gridExtra)  # For arranging multiple plots

# Load the cleaned data
source("code/preprocessing/01_import_and_clean_data.R")

# Load custom theme
source("code/analysis/theme_nature_neuroscience.R")

cat("=== CORRECTED COMPREHENSIVE BASIC ANALYSIS FOR CWT FMRI PROJECT ===\n")
cat("Accounting for counterbalanced orders and jitter\n")
cat("Analysis started at:", Sys.time(), "\n\n")

# =============================================================================
# IDENTIFY COUNTERBALANCED ORDERS
# =============================================================================

cat("IDENTIFYING COUNTERBALANCED ORDERS\n")
cat("==================================\n")

# Get reversal patterns for each subject
reversal_patterns <- df %>%
  group_by(SubNo) %>%
  summarise(
    reversal_trials = list(unique(TrialNo[TrialsSinceRev == 1])),
    .groups = 'drop'
  )

# Convert to strings for comparison
pattern_strings <- sapply(reversal_patterns$reversal_trials, paste, collapse=',')
pattern_counts <- table(pattern_strings)

# Identify the two main counterbalanced orders
# Order A: Early reversals (around trials 57-133)
# Order B: Later reversals (around trials 65-137)

# Define the main patterns for each order
order_a_patterns <- c(
  "57,69,93,101,121,133,197,205,229,237",
  "57,69,89,97,121,129,193,201,229,241",
  "1,57,69,93,101,121,133,197,205,229,237",
  "1,57,69,89,97,121,129,193,201,229,241"
)

order_b_patterns <- c(
  "65,73,97,105,125,137,193,205,229,237",
  "1,65,73,97,105,125,137,193,205,229,237"
)

# Classify subjects by order
subject_orders <- reversal_patterns %>%
  mutate(
    pattern_string = sapply(reversal_trials, paste, collapse=','),
    order = case_when(
      pattern_string %in% order_a_patterns ~ "Order A (Early)",
      pattern_string %in% order_b_patterns ~ "Order B (Late)",
      TRUE ~ "Other/Unclear"
    )
  )

# Add order information to main dataset
df_with_orders <- df %>%
  left_join(subject_orders %>% select(SubNo, order), by = "SubNo")

cat("Order classification:\n")
order_summary <- subject_orders %>%
  group_by(order) %>%
  summarise(
    n_subjects = n(),
    percentage = round(n() / nrow(subject_orders) * 100, 1)
  )
print(order_summary)

# =============================================================================
# CORRECTED LEARNING ANALYSIS BY ORDER
# =============================================================================

cat("\n\nCORRECTED LEARNING ANALYSIS BY COUNTERBALANCED ORDER\n")
cat("===================================================\n")

# Learning after reversals - separated by order
learning_by_order <- df_with_orders %>%
  filter(order != "Other/Unclear") %>%
  group_by(TrialsSinceRev, TrialValidity2, StimNoise, order) %>%
  summarise(
    accuracy = mean(Accuracy, na.rm = TRUE),
    rt = mean(ResponseRT, na.rm = TRUE),
    confidence = mean(RawConfidence, na.rm = TRUE),
    n_trials = n()
  ) %>%
  filter(n_trials >= 5)  # Only show points with sufficient data

# Calculate SEM for each condition
learning_with_sem_by_order <- learning_by_order %>%
  group_by(TrialsSinceRev, TrialValidity2, StimNoise, order) %>%
  summarise(
    accuracy = mean(accuracy, na.rm = TRUE),
    accuracy_sem = sd(accuracy, na.rm = TRUE) / sqrt(n()),
    confidence = mean(confidence, na.rm = TRUE),
    confidence_sem = sd(confidence, na.rm = TRUE) / sqrt(n()),
    n_trials = n(),
    .groups = 'drop'
  ) %>%
  filter(n_trials >= 3)  # Only show points with sufficient data

# Create plots for each order and noise condition
# Order A - Low Noise
order_a_low_noise <- learning_with_sem_by_order %>%
  filter(order == "Order A (Early)" & StimNoise == "low noise")

p_order_a_low <- ggplot(order_a_low_noise, 
                        aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Order A (Early Reversals): Low Noise Learning",
       subtitle = "Valid cues should increase accuracy, Invalid cues should decrease it\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# Order A - High Noise
order_a_high_noise <- learning_with_sem_by_order %>%
  filter(order == "Order A (Early)" & StimNoise == "high noise")

p_order_a_high <- ggplot(order_a_high_noise, 
                         aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Order A (Early Reversals): High Noise Learning",
       subtitle = "Stronger effects expected - cues should matter more for ambiguous faces\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# Order B - Low Noise
order_b_low_noise <- learning_with_sem_by_order %>%
  filter(order == "Order B (Late)" & StimNoise == "low noise")

p_order_b_low <- ggplot(order_b_low_noise, 
                        aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Order B (Late Reversals): Low Noise Learning",
       subtitle = "Valid cues should increase accuracy, Invalid cues should decrease it\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# Order B - High Noise
order_b_high_noise <- learning_with_sem_by_order %>%
  filter(order == "Order B (Late)" & StimNoise == "high noise")

p_order_b_high <- ggplot(order_b_high_noise, 
                         aes(x = TrialsSinceRev, y = accuracy, color = TrialValidity2)) +
  geom_ribbon(aes(ymin = accuracy - accuracy_sem, ymax = accuracy + accuracy_sem, 
                  fill = TrialValidity2), alpha = 0.2, color = NA) +
  geom_smooth(method = "loess", se = FALSE, size = 2, span = 0.8) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7, size = 1) +
  labs(title = "Order B (Late Reversals): High Noise Learning",
       subtitle = "Stronger effects expected - cues should matter more for ambiguous faces\nShaded areas = ±SEM, Lines = smoothed trends",
       x = "Trials Since Reversal", y = "Accuracy", 
       color = "Cue Validity", fill = "Cue Validity") +
  scale_y_continuous(labels = scales::percent, limits = c(0.4, 1)) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"),
        legend.position = "bottom")

# Combine all plots
p_corrected_learning_combined <- grid.arrange(
  p_order_a_low, p_order_a_high, p_order_b_low, p_order_b_high, 
  ncol = 2, nrow = 2
)

ggsave("results/figures/basic_analysis/learning_after_reversals_corrected.png", 
       p_corrected_learning_combined, width = 20, height = 12, bg = "white")

# =============================================================================
# LEARNING EFFECTS SUMMARY BY ORDER
# =============================================================================

cat("\nLEARNING EFFECTS SUMMARY BY COUNTERBALANCED ORDER\n")
cat("================================================\n")

# Analyze learning effects by condition and order
learning_effects_by_order <- learning_by_order %>%
  group_by(TrialValidity2, StimNoise, order) %>%
  summarise(
    early_accuracy = mean(accuracy[TrialsSinceRev <= 5], na.rm = TRUE),
    late_accuracy = mean(accuracy[TrialsSinceRev > 10], na.rm = TRUE),
    learning_effect = late_accuracy - early_accuracy,
    early_confidence = mean(confidence[TrialsSinceRev <= 5], na.rm = TRUE),
    late_confidence = mean(confidence[TrialsSinceRev > 10], na.rm = TRUE),
    confidence_learning = late_confidence - early_confidence,
    .groups = 'drop'
  )

cat("Learning effects by condition and order (late - early performance):\n")
print(learning_effects_by_order)

# Create a learning effect summary plot by order
p_learning_effects_by_order <- ggplot(learning_effects_by_order, 
                                     aes(x = TrialValidity2, y = learning_effect, fill = StimNoise)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  facet_wrap(~order, ncol = 2) +
  labs(title = "Learning Effects After Reversals by Counterbalanced Order",
       subtitle = "Positive values = improvement, Negative = decline\nExpected: Valid cues improve, Invalid cues decline",
       x = "Cue Validity", y = "Learning Effect (Late - Early Accuracy)", fill = "Stimulus Noise") +
  scale_y_continuous(labels = scales::percent) +
  theme_nature_neuroscience() +
  theme(panel.background = element_rect(fill = "white"))

ggsave("results/figures/basic_analysis/learning_effects_by_order.png", 
       p_learning_effects_by_order, width = 16, height = 8, bg = "white")

cat("\nAnalysis completed at:", Sys.time(), "\n")
cat("Corrected plots saved to results/figures/basic_analysis/\n") 