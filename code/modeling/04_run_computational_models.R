# Computational Modeling for CWT fMRI Project
# Simple script to run reinforcement learning models

# Load libraries
library(tidyverse)
library(hBayesDM)

# Load the cleaned data (run 01_import_and_clean_data.R first)
source("code/preprocessing/01_import_and_clean_data.R")

cat("=== COMPUTATIONAL MODELING ===\n")

# Prepare data for modeling
cat("Preparing data for ug_delta model...\n")

# Convert factors to numeric for modeling
df_numeric <- df %>%
  mutate(
    CueImg = as.numeric(CueImg) - 1,      # Convert to 0/1
    FaceEmot = as.numeric(FaceEmot) - 1,   # Convert to 0/1
    FaceResponse = as.numeric(FaceResponse) - 1  # Convert to 0/1
  )

# Select and rename columns for ug_delta model
model_data <- df_numeric %>%
  select(SubNo, CueImg, FaceEmot, FaceResponse) %>%
  rename(
    sub_id = SubNo,      # Subject identifier
    cue = CueImg,        # Predictor/cue (0/1)
    outcome = FaceEmot,  # Outcome/reward (0=Angry, 1=Happy)
    choice = FaceResponse # Participant's choice (0=Angry, 1=Happy)
  )

# Save the prepared data
write.table(model_data, file = "data/processed/model_data.txt", 
            sep = "\t", row.names = FALSE, col.names = TRUE)
cat("Model data saved to data/processed/model_data.txt\n")

# Fit the ug_delta model
cat("Fitting ug_delta model...\n")
cat("This may take several minutes...\n")

fit <- ug_delta(
  data = model_data,
  niter = 4000,
  nwarmup = 2000,
  nchain = 4,
  ncore = 4,
  modelRegressor = FALSE
)

# Save the model results
saveRDS(fit, "results/models/ug_delta_fit.rds")
cat("Model saved to results/models/ug_delta_fit.rds\n")

# Print summary
cat("\n=== MODEL SUMMARY ===\n")
summary(fit)

cat("\nComputational modeling complete!\n")
cat("Model results saved to results/models/\n") 