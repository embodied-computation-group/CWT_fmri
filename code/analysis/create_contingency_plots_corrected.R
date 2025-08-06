# Create Individual Subject Contingency Structure Plots - CORRECTED VERSION
# This script calculates observed P(happy|cue) within blocks to show step-wise structure

# Load libraries
library(tidyverse)
library(ggplot2)

# Load the cleaned data
source("code/preprocessing/01_import_and_clean_data.R")

# Load custom theme
source("code/analysis/theme_nature_neuroscience.R")

# Create output directory
output_dir <- "results/figures/basic_analysis/subject_reversal_plots"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cat("Creating individual subject contingency structure plots (CORRECTED)...\n")

# Get unique subjects
subjects <- unique(df$SubNo)
cat("Total subjects to process:", length(subjects), "\n")

# Process each subject
for (i in seq_along(subjects)) {
  subject_id <- subjects[i]
  
  # Get data for this subject
  subject_data <- df %>%
    filter(SubNo == subject_id) %>%
    arrange(TrialNo)
  
  # Calculate observed probabilities
  subject_data <- subject_data %>%
    mutate(
      cue_type = ifelse(CueImg == 0, "Cue A", "Cue B"),
      is_happy = ifelse(FaceEmot == "Happy", 1, 0)
    )
  
  # Get reversal points for this subject
  reversal_points <- subject_data %>%
    filter(TrialsSinceRev == 1) %>%
    pull(TrialNo)
  
  # Calculate observed P(happy|cue) within each block
  # We'll calculate the probability within each block between reversals
  
  # First, let's identify the blocks
  subject_data <- subject_data %>%
    mutate(
      block_id = cumsum(TrialsSinceRev == 1)
    )
  
  # Calculate observed probabilities within each block for each cue
  block_probs <- subject_data %>%
    group_by(block_id, cue_type) %>%
    summarise(
      p_happy = mean(is_happy, na.rm = TRUE),
      n_trials = n(),
      start_trial = min(TrialNo),
      end_trial = max(TrialNo),
      .groups = 'drop'
    ) %>%
    filter(n_trials >= 5)  # Only include blocks with sufficient data
  
  # Create step-wise plot data
  plot_data <- block_probs %>%
    group_by(cue_type) %>%
    arrange(start_trial) %>%
    mutate(
      # Create step-wise lines by repeating the probability for each trial in the block
      trial_sequence = map2(start_trial, end_trial, ~seq(.x, .y, by = 1))
    ) %>%
    unnest(trial_sequence) %>%
    select(cue_type, trial_sequence, p_happy) %>%
    rename(TrialNo = trial_sequence)
  
  # Create the contingency structure plot
  p <- ggplot() +
    # Cue A line (step-wise)
    geom_line(data = plot_data %>% filter(cue_type == "Cue A"), 
              aes(x = TrialNo, y = p_happy), 
              color = "purple", size = 1.2) +
    # Cue B line (step-wise)
    geom_line(data = plot_data %>% filter(cue_type == "Cue B"), 
              aes(x = TrialNo, y = p_happy), 
              color = "green", size = 1.2, linetype = "dashed") +
    # Reversal points
    geom_vline(xintercept = reversal_points, color = "red", linetype = "dashed", 
               alpha = 0.8, size = 0.8) +
    # Labels and styling
    labs(
      title = paste("Subject", subject_id, "- Observed Contingency Structure (Corrected)"),
      subtitle = paste("Purple = P(happy|Cue A), Green = P(happy|Cue B), Red lines = reversal points (", 
                      length(reversal_points), " reversals)"),
      x = "Trial Number", 
      y = "P (happy | cue)"
    ) +
    scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
    scale_x_continuous(breaks = seq(0, max(subject_data$TrialNo), by = 50)) +
    theme_nature_neuroscience() +
    theme(
      panel.background = element_rect(fill = "white"),
      plot.title = element_text(size = 12),
      plot.subtitle = element_text(size = 10)
    )
  
  # Save the plot
  filename <- paste0(output_dir, "/subject_", subject_id, "_corrected_contingency.png")
  ggsave(filename, p, width = 8, height = 6, dpi = 150, bg = "white")
  
  # Progress indicator
  if (i %% 20 == 0) {
    cat("Processed", i, "of", length(subjects), "subjects\n")
  }
  
  # Process all subjects (removed limit)
}

cat("\nCompleted! Generated corrected contingency plots\n")
cat("Plots saved to:", output_dir, "\n") 