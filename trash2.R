# Prepare the data with the required columns
model_data <- df %>%
  select(SubNo, CueImg, FaceResponse) %>%
  rename(
    subjID = SubNo,
    offer = CueImg,
    accept = FaceResponse
  )

# Save the data as a tab-delimited text file
write.table(model_data, file = "model_data.txt", sep = "\t", row.names = FALSE, col.names = TRUE)

# Path to the data file
data_path <- "model_data.txt"

# Run the model
fit <- ug_delta(data = data_path, niter = 4000, nwarmup = 2000, nchain = 4, nthin = 1, ncore = 4, modelRegressor = FALSE)
