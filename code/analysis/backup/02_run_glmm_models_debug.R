library(lme4)
library(lmerTest)
library(ordinal)
library(glmmTMB)
library(tidyverse)
library(DHARMa)
library(sjPlot)
library(sjmisc)

cat("Loading data...\n")
source("code/preprocessing/01_import_and_clean_data.R")

cat("Data loaded successfully. Data frame dimensions:", dim(df), "\n")
cat("Variables in data frame:", paste(names(df), collapse=", "), "\n")

# Convert confidence to 0-1 scale
df$RawConfidence <- df$RawConfidence/100 

# Convert accuracy to factor
df$Accuracy <- factor(df$Accuracy, 
                      levels = c(0, 1), 
                      labels = c("miss", "hit"))

# Create numeric version of TrialValidity2
df$TrialValidity2_numeric <- recode(df$TrialValidity2, 
                                    "Valid" = 1, 
                                    "non-predictive" = 0, 
                                    "Invalid" = -1)

# Create SignaledFace variable
df <- df %>%
  mutate(SignaledFace = case_when(
    TrialValidity == "Valid" & CueImg == "0" ~ as.character(FaceEmot),
    TrialValidity == "Valid" & CueImg == "1" ~ as.character(FaceEmot),
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Happy" ~ "Angry",
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Angry" ~ "Happy",
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Happy" ~ "Angry",
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Angry" ~ "Happy",
    TRUE ~ NA_character_
  ))

df$SignaledFace <- factor(df$SignaledFace, levels = c("Happy", "Angry"))

# Scale TrialsSinceRev within subjects
df <- df %>%
  group_by(SubNo) %>%
  mutate(TrialsSinceRev_scaled = scale(TrialsSinceRev, center = TRUE, scale = TRUE)) %>%
  ungroup()

cat("Data preprocessing completed.\n")

# Set control options for better convergence
control_options <- glmmTMBControl(
  optimizer = optim,
  optArgs = list(method = "BFGS"),
  optCtrl = list(maxit = 10000)
)

cat("Starting GLMM analyses...\n")

# 1. Simple confidence model with trial number
cat("Fitting confidence model with trial number...\n")
tryCatch({
  conf_fit_trial <- glmmTMB(RawConfidence ~ TrialNo + (1 + TrialNo| SubNo),
                       data=df,
                       family=ordbeta(),
                       start=list(psi = c(0, 1)))
  cat("✓ Confidence model with trial number completed successfully\n")
  print(summary(conf_fit_trial))
}, error = function(e) {
  cat("✗ Error in confidence model with trial number:", e$message, "\n")
})

# 2. Main confidence model
cat("Fitting main confidence model...\n")
tryCatch({
  conf_fit1 <- glmmTMB(RawConfidence ~ TrialValidity2_numeric*TrialsSinceRev*StimNoise*Accuracy + 
                        (1 + Accuracy + StimNoise + TrialValidity2_numeric | SubNo),
                      data=df,
                      family=ordbeta(),
                      start=list(psi = c(0, 1)), 
                      control = control_options)
  cat("✓ Main confidence model completed successfully\n")
  print(summary(conf_fit1))
}, error = function(e) {
  cat("✗ Error in main confidence model:", e$message, "\n")
})

# 3. Simplified confidence model
cat("Fitting simplified confidence model...\n")
tryCatch({
  model <- glmmTMB(
    RawConfidence ~ TrialValidity2_numeric * StimNoise * TrialsSinceRev_scaled + 
      (1 + TrialValidity2_numeric + StimNoise + TrialsSinceRev_scaled | SubNo),
    data = df,
    family = ordbeta(),
    start=list(psi = c(0, 1)), 
    control = control_options)
  cat("✓ Simplified confidence model completed successfully\n")
  print(summary(model))
}, error = function(e) {
  cat("✗ Error in simplified confidence model:", e$message, "\n")
})

# 4. Accuracy model
cat("Fitting accuracy model...\n")
tryCatch({
  model <- glmmTMB(Accuracy ~ TrialValidity2*StimNoise + FaceEmot + CueImg + 
                   (1+ FaceEmot + CueImg | SubNo),
                 data = df, 
                 family = binomial(link = "logit"), 
                 control = control_options)
  cat("✓ Accuracy model completed successfully\n")
  print(summary(model))
}, error = function(e) {
  cat("✗ Error in accuracy model:", e$message, "\n")
})

# 5. Response time model
cat("Fitting response time model...\n")
df_rt <- df %>% 
  na.omit()

tryCatch({
  rtmodel <- glmmTMB(ResponseRT ~ StimNoise * TrialValidity2 +
                    (1 + FaceEmot + StimNoise | SubNo), 
                  data = df_rt, 
                  family = Gamma(link = "log"))
  cat("✓ Response time model completed successfully\n")
  print(summary(rtmodel))
}, error = function(e) {
  cat("✗ Error in response time model:", e$message, "\n")
})

# 6. Choice model (filtered for high noise)
cat("Fitting choice model (high noise only)...\n")
df_filt <- df %>% 
  filter(StimNoise == "high noise")

tryCatch({
  choice_model <- glmmTMB(FaceResponse ~ SignaledFace * FaceEmot * TrialsSinceRev + 
                          (1 + FaceEmot | SubNo),
                        data = df_filt, 
                        family = binomial(link = "logit"), 
                        control = control_options)
  cat("✓ Choice model completed successfully\n")
  print(summary(choice_model))
}, error = function(e) {
  cat("✗ Error in choice model:", e$message, "\n")
})

cat("GLMM analysis completed!\n") 