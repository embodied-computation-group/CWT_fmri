# =============================================================================
# Computational Modeling Analysis for CWT fMRI Project
# =============================================================================
# 
# This script implements reinforcement learning models to analyze participant
# behavior in the face emotion recognition task using the hBayesDM package.
# 
# Models implemented:
# - ug_delta: Uncertainty-guided delta learning model
# 
# Author: [Your Name]
# Date: [Current Date]
# 
# Dependencies:
# - tidyverse: Data manipulation and visualization
# - hBayesDM: Hierarchical Bayesian modeling for decision-making tasks
# =============================================================================

# Load required libraries
library(tidyverse)
library(hBayesDM)

# =============================================================================
# Data Preparation for Computational Modeling
# =============================================================================

#' Prepare data for reinforcement learning models
#' 
#' This function converts the behavioral data into the format required by hBayesDM
#' models, specifically for the ug_delta model which implements uncertainty-guided
#' learning.
#' 
#' @param df Data frame containing behavioral data (must be loaded from getdata.R)
#' @param model_type Type of model to prepare data for ("ug_delta" or "rw_decay")
#' @return Data frame formatted for hBayesDM modeling
prepare_model_data <- function(df, model_type = "ug_delta") {
  
  # Ensure factors are numeric for modeling
  df_numeric <- df %>%
    mutate(
      CueImg = as.numeric(CueImg) - 1,      # Convert to 0/1
      FaceEmot = as.numeric(FaceEmot) - 1,   # Convert to 0/1
      FaceResponse = as.numeric(FaceResponse) - 1  # Convert to 0/1
    )
  
  if (model_type == "ug_delta") {
    # Prepare data for ug_delta model (uncertainty-guided learning)
    model_data <- df_numeric %>%
      select(SubNo, CueImg, FaceEmot, FaceResponse) %>%
      rename(
        sub_id = SubNo,      # Subject identifier
        cue = CueImg,        # Predictor/cue (0/1)
        outcome = FaceEmot,  # Outcome/reward (0=Angry, 1=Happy)
        choice = FaceResponse # Participant's choice (0=Angry, 1=Happy)
      )
    
    return(model_data)
    
  } else if (model_type == "rw_decay") {
    # Prepare data for rw_decay model (rescorla-wagner with decay)
    model_data <- df_numeric %>%
      select(SubNo, TrialNo, CueImg, FaceEmot, FaceResponse, TrialsSinceRev, Accuracy) %>%
      rename(
        sub_id = SubNo,
        trial = TrialNo,
        cue = CueImg,
        outcome = FaceEmot,
        choice = FaceResponse,
        trials_since_rev = TrialsSinceRev,
        accuracy = Accuracy
      )
    
    return(model_data)
    
  } else {
    stop("Model type not supported. Use 'ug_delta' or 'rw_decay'")
  }
}

# =============================================================================
# Model Fitting Functions
# =============================================================================

#' Fit uncertainty-guided delta learning model
#' 
#' Fits the ug_delta model from hBayesDM which implements uncertainty-guided
#' learning. This model is particularly suitable for tasks where participants
#' must learn from feedback and adapt to changing contingencies.
#' 
#' @param data Prepared data frame for modeling
#' @param niter Number of iterations for MCMC sampling (default: 4000)
#' @param nwarmup Number of warmup iterations (default: 2000)
#' @param nchain Number of MCMC chains (default: 4)
#' @param ncore Number of cores for parallel processing (default: 4)
#' @param modelRegressor Whether to return model regressors (default: FALSE)
#' @return Fitted model object
fit_ug_delta_model <- function(data, 
                               niter = 4000, 
                               nwarmup = 2000, 
                               nchain = 4, 
                               ncore = 4, 
                               modelRegressor = FALSE) {
  
  cat("Fitting ug_delta model...\n")
  cat("Parameters: niter =", niter, ", nwarmup =", nwarmup, 
      ", nchain =", nchain, ", ncore =", ncore, "\n")
  
  # Fit the model
  fit <- ug_delta(
    data = data,
    niter = niter,
    nwarmup = nwarmup,
    nchain = nchain,
    ncore = ncore,
    modelRegressor = modelRegressor
  )
  
  cat("Model fitting completed!\n")
  return(fit)
}

#' Save model data to file
#' 
#' Saves the prepared model data to a tab-delimited text file for external
#' analysis or backup purposes.
#' 
#' @param model_data Prepared model data
#' @param filename Output filename (default: "model_data.txt")
save_model_data <- function(model_data, filename = "model_data.txt") {
  write.table(model_data, 
              file = filename, 
              sep = "\t", 
              row.names = FALSE, 
              col.names = TRUE)
  cat("Model data saved to:", filename, "\n")
}

# =============================================================================
# Main Analysis Pipeline
# =============================================================================

#' Run complete computational modeling analysis
#' 
#' This function runs the full computational modeling pipeline including
#' data preparation, model fitting, and result summarization.
#' 
#' @param df Behavioral data frame (must be loaded from getdata.R)
#' @param save_data Whether to save prepared data to file (default: TRUE)
#' @param model_params List of model parameters (optional)
#' @return List containing fitted model and summary statistics
run_computational_modeling <- function(df, 
                                     save_data = TRUE, 
                                     model_params = NULL) {
  
  cat("Starting computational modeling analysis...\n")
  cat("=", 50, "\n")
  
  # Set default parameters if not provided
  if (is.null(model_params)) {
    model_params <- list(
      niter = 4000,
      nwarmup = 2000,
      nchain = 4,
      ncore = 4,
      modelRegressor = FALSE
    )
  }
  
  # Prepare data for ug_delta model
  cat("Preparing data for ug_delta model...\n")
  model_data <- prepare_model_data(df, model_type = "ug_delta")
  
  # Save data if requested
  if (save_data) {
    save_model_data(model_data)
  }
  
  # Fit the model
  fit <- fit_ug_delta_model(model_data, 
                           niter = model_params$niter,
                           nwarmup = model_params$nwarmup,
                           nchain = model_params$nchain,
                           ncore = model_params$ncore,
                           modelRegressor = model_params$modelRegressor)
  
  # Generate summary
  cat("\nModel Summary:\n")
  cat("=", 30, "\n")
  summary_fit <- summary(fit)
  
  # Return results
  results <- list(
    model = fit,
    summary = summary_fit,
    data = model_data,
    parameters = model_params
  )
  
  cat("\nComputational modeling analysis completed!\n")
  return(results)
}

# =============================================================================
# Example Usage (Uncomment to run)
# =============================================================================

# # Load data (assuming getdata.R has been run)
# # source("getdata.R")
# 
# # Run the complete analysis
# results <- run_computational_modeling(df)
# 
# # Access results
# model_fit <- results$model
# model_summary <- results$summary
# 
# # Additional analysis can be performed on the fitted model
# # plot(model_fit)  # Plot model diagnostics
# # print(model_summary)  # Print detailed summary

# =============================================================================
# Notes on Model Interpretation
# =============================================================================
#
# The ug_delta model implements uncertainty-guided learning where:
# - Participants learn from feedback about their choices
# - Learning rate adapts based on uncertainty
# - Model captures individual differences in learning strategies
#
# Key parameters:
# - mu_A: Mean of the learning rate for the A option
# - mu_B: Mean of the learning rate for the B option  
# - mu_eta: Mean of the inverse temperature
# - mu_xi: Mean of the noise parameter
#
# Higher learning rates indicate faster adaptation to feedback
# Higher inverse temperature indicates more deterministic choices
# Higher noise indicates more random choice behavior
#
# ============================================================================= 