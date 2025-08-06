# -----------------------------------------------------------------------------
# PRECISION-WEIGHTED REINFORCEMENT LEARNING MODEL FOR CWT fMRI DATA
# -----------------------------------------------------------------------------
#
# MODEL:
# This script implements a Q-learning model where the learning rate is
# modulated by the precision (i.e., noise level) of the outcome stimulus.
#
# VERSION 5.0 - ADDED POSTERIOR PREDICTIVE CHECKS
# This version adds a crucial model validation step: posterior predictive
# checking. For each subject, it simulates data from the fitted model and
# plots it against the real data to visually inspect the quality of the fit.
#
# FREE PARAMETERS:
#   - alpha (α): Base learning rate (0 to 1)
#   - beta (β): Inverse temperature for softmax choice rule (0 to Inf)
#   - omega (ω): Precision weight, controlling noise impact (0 to 1)
#
# ADAPTED FOR CWT fMRI DATA STRUCTURE
# -----------------------------------------------------------------------------

# 1. LOAD NECESSARY LIBRARIES
# -----------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(tidyverse)

# Load custom Nature Neuroscience theme
source("code/analysis/theme_nature_neuroscience.R")

cat("=== Precision-Weighted RL Model Analysis ===\n")

# 2. LOAD AND PREPROCESS CWT DATA
# -----------------------------------------------------------------------------
cat("Loading CWT data...\n")
source("code/preprocessing/01_import_and_clean_data.R")

# Prepare data for RL model
cat("Preparing data for RL model...\n")

# Convert data to RL model format
rl_data <- df %>%
  # Select relevant columns
  select(SubNo, TrialNo, CueImg, StimNoise, FaceEmot, FaceResponse, Accuracy) %>%
  # Rename columns to match RL model expectations
  rename(
    Trial = TrialNo,
    Cue = CueImg,
    CorrectEmot = FaceEmot,
    Choice = FaceResponse
  ) %>%
  # Convert to numeric format for RL model
  mutate(
    # Convert cues to 1/2 (ensure they are 1 and 2)
    Cue = as.numeric(as.character(Cue)) + 1,
    # Convert emotions to 1/2 (Angry->1, Happy->2)
    CorrectEmot = ifelse(CorrectEmot == "Angry", 1, 2),
    Choice = ifelse(Choice == "Angry", 1, 2),
    # Convert noise to 0/1 (low->0, high->1)
    StimNoise = ifelse(StimNoise == "low noise", 0, 1)
  ) %>%
  # Remove any NA values
  na.omit() %>%
  # Sort by subject and trial
  arrange(SubNo, Trial)

# Debug: Check the data structure
cat("Data structure check:\n")
cat("Cue values:", unique(rl_data$Cue), "\n")
cat("CorrectEmot values:", unique(rl_data$CorrectEmot), "\n")
cat("Choice values:", unique(rl_data$Choice), "\n")
cat("StimNoise values:", unique(rl_data$StimNoise), "\n")
cat("Number of subjects:", length(unique(rl_data$SubNo)), "\n")
cat("Trials per subject range:", range(table(rl_data$SubNo)), "\n\n")

# Validate and fix data if needed
if (!all(unique(rl_data$Cue) %in% c(1, 2))) {
  cat("Fixing cue values...\n")
  rl_data$Cue <- ifelse(rl_data$Cue == 2, 1, 2)
}

if (!all(unique(rl_data$CorrectEmot) %in% c(1, 2))) {
  cat("Fixing CorrectEmot values...\n")
  rl_data$CorrectEmot <- ifelse(rl_data$CorrectEmot == 1, 1, 2)
}

if (!all(unique(rl_data$Choice) %in% c(1, 2))) {
  cat("Fixing Choice values...\n")
  rl_data$Choice <- ifelse(rl_data$Choice == 1, 1, 2)
}

cat("After validation:\n")
cat("Cue values:", unique(rl_data$Cue), "\n")
cat("CorrectEmot values:", unique(rl_data$CorrectEmot), "\n")
cat("Choice values:", unique(rl_data$Choice), "\n\n")

cat("Data prepared successfully.\n")
cat("Number of subjects:", length(unique(rl_data$SubNo)), "\n")
cat("Total trials:", nrow(rl_data), "\n")
cat("Trials per subject:", nrow(rl_data) / length(unique(rl_data$SubNo)), "\n\n")

# 3. DEFINE THE LIKELIHOOD FUNCTION
# -----------------------------------------------------------------------------
q_learning_likelihood <- function(params, data) {
  
  # Extract parameters with meaningful names
  alpha <- params[1] # Base learning rate
  beta  <- params[2] # Inverse temperature
  omega <- params[3] # Precision weight
  
  # Initialize Q-values for the two cues and two actions (happy/angry)
  # Q[cue, action]
  Q <- matrix(0.5, nrow = 2, ncol = 2)
  
  # Variable to store the total log-likelihood
  total_log_likelihood <- 0
  
  # Loop through each trial for the participant
  for (t in 1:nrow(data)) {
    # Get trial-specific information
    current_cue   <- data$Cue[t]
    participant_choice <- data$Choice[t]
    stim_noise    <- data$StimNoise[t]
    correct_emotion <- data$CorrectEmot[t]
    
    # Debug: Check for invalid indices
    if (is.na(current_cue) || is.na(participant_choice) || 
        current_cue < 1 || current_cue > 2 || 
        participant_choice < 1 || participant_choice > 2) {
      return(Inf)  # Return high value to indicate bad fit
    }
    
    # --- Softmax Choice Rule ---
    # Calculate the probability of choosing each action for the current cue
    q_values_for_cue <- Q[current_cue, ]
    prob_actions <- exp(beta * q_values_for_cue) / sum(exp(beta * q_values_for_cue))
    
    # --- Calculate Likelihood ---
    # Get the likelihood of the participant's actual choice
    # We add a small number to prevent log(0) errors
    likelihood <- prob_actions[participant_choice]
    total_log_likelihood <- total_log_likelihood + log(likelihood + 1e-9)
    
    # --- Learning/Update Rule ---
    # Calculate the effective learning rate based on stimulus noise
    effective_alpha <- alpha * (1 - omega * stim_noise)
    
    # Determine the reward for the chosen action
    # Reward is 1 if the choice matched the actual emotion, 0 otherwise
    reward <- ifelse(participant_choice == correct_emotion, 1, 0)
    
    # Calculate the prediction error (PE)
    prediction_error <- reward - Q[current_cue, participant_choice]
    
    # Update the Q-value for the chosen action
    Q[current_cue, participant_choice] <- Q[current_cue, participant_choice] + effective_alpha * prediction_error
  }
  
  # Return the NEGATIVE log-likelihood for minimization
  return(-total_log_likelihood)
}

# 4. CREATE A WRAPPER FUNCTION FOR FITTING (WITH GRID SEARCH)
# -----------------------------------------------------------------------------
# This function takes a participant's data, performs a two-stage fit,
# and returns the best-fitting parameters.
# -----------------------------------------------------------------------------
fit_subject <- function(subject_data) {

  subject_id <- unique(subject_data$SubNo)
  
  # --- Stage 1: Coarse Grid Search ---
  cat(paste("--- Starting Grid Search for Subject:", subject_id, "---\n"))
  
  # Define a coarse grid of plausible parameter values.
  # This doesn't need to be too dense; its goal is to find the right region.
  grid_params <- expand.grid(
    alpha = seq(0.1, 0.9, by = 0.25),
    beta  = seq(1, 9, by = 2.5),
    omega = seq(0.1, 0.9, by = 0.25)
  )

  # Calculate the likelihood for every combination of parameters on the grid.
  # 'apply' runs a function over the rows (1) of the grid_params data frame.
  grid_results <- apply(grid_params, 1, function(p) {
    q_learning_likelihood(params = p, data = subject_data)
  })

  # Find the best set of parameters from the grid search
  best_grid_params <- grid_params[which.min(grid_results), ]
  cat("Best grid point found:", as.numeric(best_grid_params), "\n")

  # --- Stage 2: Fine-Tuning with 'optim' ---
  # Use the best parameters from the grid search as the starting point
  # for the gradient-based optimizer to find the precise minimum.
  lower_bounds <- c(0, 0, 0)
  upper_bounds <- c(1, 15, 1) # Beta upper bound can be adjusted if needed

  fit <- optim(
    par = as.numeric(best_grid_params), # Use best grid point as the start
    fn = q_learning_likelihood,
    data = subject_data,
    method = "L-BFGS-B",
    lower = lower_bounds,
    upper = upper_bounds,
    control = list(fnscale = 1)
  )

  # Return a data frame with the final, optimized results
  return(data.frame(
    SubNo = subject_id,
    alpha = fit$par[1],
    beta = fit$par[2],
    omega = fit$par[3],
    neg_log_likelihood = fit$value,
    convergence = fit$convergence
  ))
}

# 5. MAIN EXECUTION: FIT THE MODEL TO EACH PARTICIPANT
# -----------------------------------------------------------------------------
cat("--- Starting Model Fitting ---\n")

# Split the data into a list of data frames, one for each subject
data_by_subject <- split(rl_data, rl_data$SubNo)

# Use lapply to apply the 'fit_subject' function to each subject's data
cat("Fitting models to", length(data_by_subject), "subjects...\n")

results_list <- lapply(data_by_subject, function(subject_data) {
  subject_id <- unique(subject_data$SubNo)
  if (length(subject_id) == 0 || is.na(subject_id)) {
    cat("Skipping subject with invalid ID\n")
    return(data.frame(
      SubNo = "unknown",
      alpha = NA,
      beta = NA,
      omega = NA,
      neg_log_likelihood = NA,
      convergence = -1
    ))
  }
  cat("Fitting subject", subject_id, "...\n")
  tryCatch({
    fit_subject(subject_data)
  }, error = function(e) {
    cat("Error fitting subject", subject_id, ":", e$message, "\n")
    return(data.frame(
      SubNo = subject_id,
      alpha = NA,
      beta = NA,
      omega = NA,
      neg_log_likelihood = NA,
      convergence = -1
    ))
  })
})

# Combine the list of results into a single, tidy data frame
final_results <- do.call(rbind, results_list)
rownames(final_results) <- NULL # Clean up row names

cat("\n--- Model Fitting Complete ---\n\n")

# 6. ANALYZE AND VISUALIZE RESULTS
# -----------------------------------------------------------------------------
cat("--- Results Summary ---\n")

# Remove failed fits
successful_fits <- final_results %>%
  filter(!is.na(alpha) & convergence == 0)

cat("Successful fits:", nrow(successful_fits), "out of", nrow(final_results), "subjects\n\n")

if (nrow(successful_fits) > 0) {
  # Summary statistics
  cat("Parameter Summary:\n")
  print(summary(successful_fits[, c("alpha", "beta", "omega")]))
  
  # Create visualizations
  cat("\nCreating visualizations...\n")
  
  # Parameter distributions
  p1 <- ggplot(successful_fits, aes(x = alpha)) +
    geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7) +
    labs(title = "Distribution of Learning Rate (α)", x = "α", y = "Count") +
    theme_nature_neuroscience()
  
  p2 <- ggplot(successful_fits, aes(x = beta)) +
    geom_histogram(bins = 20, fill = "darkgreen", alpha = 0.7) +
    labs(title = "Distribution of Inverse Temperature (β)", x = "β", y = "Count") +
    theme_nature_neuroscience()
  
  p3 <- ggplot(successful_fits, aes(x = omega)) +
    geom_histogram(bins = 20, fill = "darkred", alpha = 0.7) +
    labs(title = "Distribution of Precision Weight (ω)", x = "ω", y = "Count") +
    theme_nature_neuroscience()
  
  # Parameter correlations
  p4 <- ggplot(successful_fits, aes(x = alpha, y = omega)) +
    geom_point(alpha = 0.6) +
    geom_smooth(method = "lm", se = TRUE) +
    labs(title = "Learning Rate vs Precision Weight", 
         x = "α (Learning Rate)", y = "ω (Precision Weight)") +
    theme_nature_neuroscience()
  
  # Save plots
  ggsave("results/figures/rl_models/rl_alpha_distribution.png", p1, width = 8, height = 6, dpi = 300)
ggsave("results/figures/rl_models/rl_beta_distribution.png", p2, width = 8, height = 6, dpi = 300)
ggsave("results/figures/rl_models/rl_omega_distribution.png", p3, width = 8, height = 6, dpi = 300)
ggsave("results/figures/rl_models/rl_alpha_vs_omega.png", p4, width = 8, height = 6, dpi = 300)
  
  cat("✓ Plots saved to results/figures/\n")
  
  # Save results
  write.csv(final_results, "results/models/rl_model_results.csv", row.names = FALSE)
  saveRDS(final_results, "results/models/rl_model_results.rds")
  
  cat("✓ Results saved to results/models/\n")
  
  # Print final results
  cat("\n--- Final Results ---\n")
  print(final_results)
  
} else {
  cat("No successful model fits found.\n")
}

cat("\n=== Precision-Weighted RL Model Analysis Complete ===\n")

# -----------------------------------------------------------------------------
# 7. POSTERIOR PREDICTIVE CHECKS
# -----------------------------------------------------------------------------
# This section adds crucial model validation by simulating data from the fitted
# model and comparing it to the real data to visually inspect the quality of the fit.
# -----------------------------------------------------------------------------

# Function to simulate data from the fitted model
simulate_from_fit <- function(params, original_data) {
  
  alpha <- params$alpha
  beta  <- params$beta
  omega <- params$omega
  
  Q <- matrix(0.5, nrow = 2, ncol = 2)
  simulated_choices <- numeric(nrow(original_data))
  
  for (t in 1:nrow(original_data)) {
    current_cue   <- original_data$Cue[t]
    stim_noise    <- original_data$StimNoise[t]
    correct_emotion <- original_data$CorrectEmot[t]
    
    # --- Softmax Choice Rule ---
    q_values_for_cue <- Q[current_cue, ]
    prob_actions <- exp(beta * q_values_for_cue) / sum(exp(beta * q_values_for_cue))
    
    # --- Simulate a Choice ---
    # Make a choice based on the calculated probabilities
    simulated_choice <- sample(1:2, 1, prob = prob_actions)
    simulated_choices[t] <- simulated_choice
    
    # --- Learning/Update Rule ---
    effective_alpha <- alpha * (1 - omega * stim_noise)
    reward <- ifelse(simulated_choice == correct_emotion, 1, 0)
    prediction_error <- reward - Q[current_cue, simulated_choice]
    Q[current_cue, simulated_choice] <- Q[current_cue, simulated_choice] + effective_alpha * prediction_error
  }
  
  # Return the original data frame with an added column for simulated choices
  original_data$SimChoice <- simulated_choices
  return(original_data)
}

# Function to calculate and plot reversal-locked learning curves
plot_reversal_learning <- function(data, pre_window = 5, post_window = 15) {
  
  # Create reversal points based on CWT task structure
  # In CWT, reversals happen every ~20 trials
  reversal_points <- seq(20, max(data$Trial), by = 20)
  
  # --- Process Real Data ---
  data$Accuracy <- ifelse(data$Choice == data$CorrectEmot, 1, 0)
  data$last_reversal <- sapply(data$Trial, function(t) {
    revs <- reversal_points[reversal_points <= t]
    if (length(revs) == 0) return(0) else return(max(revs))
  })
  data$trials_since_reversal <- data$Trial - data$last_reversal
  
  real_curve <- data %>%
    filter(trials_since_reversal >= -pre_window & trials_since_reversal <= post_window) %>%
    group_by(trials_since_reversal) %>%
    summarise(mean_accuracy = mean(Accuracy), .groups = 'drop') %>%
    mutate(DataType = "Real")

  # --- Process Simulated Data ---
  data$SimAccuracy <- ifelse(data$SimChoice == data$CorrectEmot, 1, 0)
  sim_curve <- data %>%
    filter(trials_since_reversal >= -pre_window & trials_since_reversal <= post_window) %>%
    group_by(trials_since_reversal) %>%
    summarise(mean_accuracy = mean(SimAccuracy), .groups = 'drop') %>%
    mutate(DataType = "Simulated")
    
  # Combine and plot
  combined_curves <- rbind(real_curve, sim_curve)
  
  plot <- ggplot(combined_curves, aes(x = trials_since_reversal, y = mean_accuracy, color = DataType, linetype = DataType)) +
    geom_line(size = 1.1) +
    geom_point(size = 2.2) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
    geom_hline(yintercept = 0.5, linetype = "dotted", color = "grey40") +
    scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
    scale_color_manual(values = c("Real" = "black", "Simulated" = "red")) +
    scale_linetype_manual(values = c("Real" = "solid", "Simulated" = "dashed")) +
    labs(
      title = paste("Posterior Predictive Check for Subject:", unique(data$SubNo)),
      subtitle = "Comparing Real vs. Model-Simulated Behavior",
      x = "Trials Since Reversal",
      y = "Mean Accuracy",
      color = "Data Type",
      linetype = "Data Type"
    ) +
    theme_nature_neuroscience() +
    theme(legend.position = "bottom")
  
  return(plot)
}

# Function to create overall model fit summary
create_fit_summary <- function(successful_fits, rl_data) {
  
  # Calculate model fit metrics
  fit_summary <- successful_fits %>%
    summarise(
      n_subjects = n(),
      mean_alpha = mean(alpha, na.rm = TRUE),
      mean_beta = mean(beta, na.rm = TRUE),
      mean_omega = mean(omega, na.rm = TRUE),
      sd_alpha = sd(alpha, na.rm = TRUE),
      sd_beta = sd(beta, na.rm = TRUE),
      sd_omega = sd(omega, na.rm = TRUE),
      mean_nll = mean(neg_log_likelihood, na.rm = TRUE)
    )
  
  # Create overall fit plot
  overall_plot <- ggplot(successful_fits, aes(x = alpha, y = omega)) +
    geom_point(aes(size = beta, color = neg_log_likelihood), alpha = 0.7) +
    scale_size_continuous(range = c(2, 6), name = "β (Inverse Temperature)") +
    scale_color_gradient(low = "blue", high = "red", name = "Neg Log Likelihood") +
    labs(
      title = "Model Fit Summary Across All Subjects",
      subtitle = paste("N =", fit_summary$n_subjects, "subjects"),
      x = "α (Learning Rate)",
      y = "ω (Precision Weight)"
    ) +
    theme_nature_neuroscience() +
    theme(legend.position = "right")
  
  return(list(summary = fit_summary, plot = overall_plot))
}

# --- Main Posterior Predictive Check Execution ---
if (nrow(successful_fits) > 0) {
  cat("\n--- Starting Posterior Predictive Checks ---\n")
  
  # Create output directory for predictive check plots
  dir.create("results/figures/predictive_checks", showWarnings = FALSE, recursive = TRUE)
  
  # Sample a few subjects for detailed checks (to avoid too many plots)
  sample_subjects <- sample(unique(successful_fits$SubNo), min(10, nrow(successful_fits)))
  
  for (subj_id in sample_subjects) {
    # Get subject data
    subj_data <- rl_data %>% filter(SubNo == subj_id)
    
    # Get the fitted parameters for this subject
    subj_params <- successful_fits %>% filter(SubNo == subj_id)
    
    if (nrow(subj_params) > 0) {
      cat(paste("\n--- Generating predictive check for Subject:", subj_id, "---\n"))
      cat("Fitted Params (α, β, ω):", round(subj_params$alpha, 3), round(subj_params$beta, 3), round(subj_params$omega, 3), "\n")
      
      # 1. Simulate data using the fitted parameters
      simulated_data <- simulate_from_fit(subj_params, subj_data)
      
      # 2. Create the comparison plot
      comparison_plot <- plot_reversal_learning(simulated_data)
      
      # 3. Save the plot
      ggsave(paste0("results/figures/predictive_checks/subject_", subj_id, "_predictive_check.png"), 
             comparison_plot, width = 10, height = 6, dpi = 300)
      
      cat("✓ Predictive check plot saved\n")
    }
  }
  
  # Create overall fit summary
  fit_summary <- create_fit_summary(successful_fits, rl_data)
  
  # Save overall summary plot
  ggsave("results/figures/rl_models/rl_model_fit_summary.png", 
         fit_summary$plot, width = 10, height = 8, dpi = 300)
  
  cat("\n✓ Overall model fit summary saved\n")
  cat("✓ Predictive check plots saved to results/figures/predictive_checks/\n")
  
} else {
  cat("\nNo successful fits available for predictive checks.\n")
}

# -----------------------------------------------------------------------------
# INTERPRETATION OF RESULTS:
#
# - alpha: A value near 1 means rapid learning/forgetting. A value near 0
#          means very slow updating of beliefs.
# - beta: A high value (e.g., > 5) indicates deterministic choices (exploiting
#         the best option). A value near 0 indicates random choices (exploring).
# - omega: The key parameter. A value near 1 indicates that the participant
#          strongly down-weights learning on high-noise trials. A value near 0
#          indicates that stimulus noise has no impact on their learning rate.
# - neg_log_likelihood: The minimized value from the fitting process. Lower values
#                       indicate a better model fit to the data for that subject.
#
# POSTERIOR PREDICTIVE CHECKS:
# - The predictive check plots show how well the fitted model captures
#   the real learning dynamics around reversals.
# - Good fits show similar learning curves for real vs simulated data.
# - Poor fits show systematic differences between real and simulated behavior.
# ----------------------------------------------------------------------------- 