# Plot True Experimental Contingencies from MATLAB Logs
# This script extracts the true experimental design from vars[[18]] (the design matrix)

library(R.matlab)
library(tidyverse)
library(ggplot2)

# Load custom theme
source("code/analysis/theme_nature_neuroscience.R")

# Create output directory
output_dir <- "results/figures/basic_analysis/true_contingency_plots"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cat("Creating true contingency plots from MATLAB logs...\n")

# List all MATLAB files
mat_files <- list.files("data/raw/vmp_1_raw/", pattern = "\\.mat$", full.names = TRUE)
cat("Found", length(mat_files), "MATLAB log files\n")

# Function to extract subject ID from filename
extract_subject_id <- function(filename) {
  basename <- basename(filename)
  subject_id <- gsub("CWT_v1-3_", "", basename)
  subject_id <- gsub("_.*", "", subject_id)
  return(subject_id)
}

# Process each MATLAB file
for (mat_file in mat_files) {
  subject_id <- extract_subject_id(mat_file)
  cat("Processing subject", subject_id, "...\n")
  
  # Load the MATLAB file
  mat_data <- readMat(mat_file)
  vars <- mat_data$vars
  
  # Extract the true experimental design from vars[[18]] (the design matrix)
  design_matrix <- vars[[18]]
  
  if (is.null(design_matrix) || ncol(design_matrix) != 15) {
    cat("No valid design matrix found for subject", subject_id, "\n")
    next
  }
  
  # Convert to data frame with correct column names
  design_df <- data.frame(
    trial_no = design_matrix[, 1],
    condition = design_matrix[, 2],  # 1=cue_0 valid, 2=cue_1 valid, 3=cue_0 invalid, 4=cue_1 invalid, 5=non-predictive
    block_type = design_matrix[, 3],  # 1=non-predictive, 2=predictive short, 3=predictive long
    face_gender = design_matrix[, 4],  # 0=male, 1=female
    cue = design_matrix[, 5],  # 0=elephant, 1=bicycle
    trial_type = design_matrix[, 6],  # 1=valid, 2=invalid
    desired_prob = design_matrix[, 7],
    effective_prob = design_matrix[, 8],
    block_volatility = design_matrix[, 9],  # 1=volatile, 0=stable
    outcome = design_matrix[, 10],  # 0=angry, 1=happy
    predictive_trial = design_matrix[, 11],  # 1=predictive, 0=non-predictive
    cue0_prediction = design_matrix[, 12],  # 0=NP, 1=cue_0->Happy, 2=cue_0->Angry
    prediction_trial_next = design_matrix[, 13],
    reversal_blocks_sequence = design_matrix[, 14],
    blockwise_trial_number = design_matrix[, 15]
  )
  
  cat("Design matrix summary:\n")
  cat("Number of trials:", nrow(design_df), "\n")
  cat("Unique conditions:", unique(design_df$condition), "\n")
  cat("Unique cues:", unique(design_df$cue), "\n")
  cat("Unique desired probabilities:", unique(design_df$desired_prob), "\n")
  
  # Calculate observed probabilities by cue within blocks
  # Block boundaries occur when desired_prob changes
  design_df <- design_df %>%
    mutate(
      block_change = c(TRUE, diff(desired_prob) != 0),
      block_id = cumsum(block_change)
    )
  
  # Calculate observed probabilities within each block
  observed_probs <- design_df %>%
    group_by(block_id, cue) %>%
    summarise(
      observed_p_happy = mean(outcome == 1, na.rm = TRUE),
      n_trials = n(),
      start_trial = min(trial_no),
      end_trial = max(trial_no),
      desired_prob = first(desired_prob),
      effective_prob = first(effective_prob),
      block_type = first(block_type),
      condition = first(condition),
      .groups = 'drop'
    )
  
  # Check if cues are opposing within blocks
  cat("\nChecking cue opposition within blocks:\n")
  for (block in unique(observed_probs$block_id)) {
    block_data <- observed_probs %>% filter(block_id == block)
    if (nrow(block_data) == 2) {
      cue0_prob <- block_data$observed_p_happy[block_data$cue == 0]
      cue1_prob <- block_data$observed_p_happy[block_data$cue == 1]
      if (length(cue0_prob) > 0 && length(cue1_prob) > 0) {
        sum_probs <- cue0_prob + cue1_prob
        cat("Block", block, ": Cue 0 =", cue0_prob, ", Cue 1 =", cue1_prob, 
            ", Sum =", sum_probs, ifelse(abs(sum_probs - 1) < 0.1, "(opposing)", "(NOT opposing)"), "\n")
      }
    }
  }
  
  # Create the plot
  p <- ggplot() +
    # Observed probabilities for cue 0 (blue line)
    geom_step(data = observed_probs %>% filter(cue == 0), 
              aes(x = start_trial, y = observed_p_happy, color = "Cue 0 (Elephant)"), 
              linewidth = 1.5) +
    # Observed probabilities for cue 1 (green line)
    geom_step(data = observed_probs %>% filter(cue == 1), 
              aes(x = start_trial, y = observed_p_happy, color = "Cue 1 (Bicycle)"), 
              linewidth = 1.5) +
    # Block boundaries (red vertical lines)
    geom_vline(data = observed_probs %>% filter(cue == 0), 
               aes(xintercept = start_trial), 
               color = "red", linetype = "dashed", alpha = 0.8, linewidth = 0.8) +
    # Labels
    labs(
      title = paste("Subject", subject_id, "- True Experimental Contingencies"),
      x = "Trial Number",
      y = "P(Happy|cue)",
      color = "Cue Type"
    ) +
    scale_color_manual(values = c("Cue 0 (Elephant)" = "blue", "Cue 1 (Bicycle)" = "green")) +
    theme_nature_neuroscience() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(size = 12)
    ) +
    ylim(0, 1)
  
  # Save the plot
  filename <- paste0("subject_", subject_id, "_true_contingencies.png")
  ggsave(file.path(output_dir, filename), p, width = 12, height = 8, dpi = 300)
  
  cat("Saved plot for subject", subject_id, "\n")
  
  # Print summary of the design
  cat("True experimental design for subject", subject_id, ":\n")
  print(observed_probs[, c("block_id", "cue", "start_trial", "end_trial", "observed_p_happy", "desired_prob", "block_type", "condition", "n_trials")])
  cat("\n")
}

cat("Completed! Plots saved to:", output_dir, "\n") 