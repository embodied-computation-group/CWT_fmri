library(tidyverse)
library(hBayesDM)
# Ensure the factors are numeric or coded correctly for modeling
df <- df %>%
  mutate(CueImg = as.numeric(CueImg) - 1,  # Convert to 0/1
         FaceEmot = as.numeric(FaceEmot) - 1,  # Convert to 0/1
         FaceResponse = as.numeric(FaceResponse) - 1)  # Convert to 0/1

# Select relevant columns for the model
model_data <- df %>%
  select(SubNo, TrialNo, CueImg, FaceEmot, FaceResponse, TrialsSinceRev, Accuracy)


# Prepare data for the rw_decay model
# You need to create a list format that hBayesDM expects
# Create the data structure for ug_delta
model_data <- df %>%
  select(SubNo, CueImg, FaceEmot, FaceResponse) %>%
  rename(
    sub_id = SubNo,
    cue = CueImg,  # predictor/cue
    outcome = FaceEmot,  # outcome/reward
    choice = FaceResponse  # participant's choice
  )

# Fit the model
fit <- ug_delta(data = model_data, niter = 4000, nwarmup = 2000, nchain = 4, ncore = 4 , modelRegressor = FALSE)

# Summarize the model results
summary(fit)
