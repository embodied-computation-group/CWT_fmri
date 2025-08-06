library(readr)

CWT_vmp1_master <- read_csv("data/raw/CWT_vmp1_master.csv", na = "NaN")

str(CWT_vmp1_master)

# Load necessary library
library(tidyverse)

# Assume the data frame is named df
df <- CWT_vmp1_master %>% 
  filter()

# 1. Set SubNo and all boolean variables (except for Accuracy) to factors
df <- df %>%
  filter(PredictResp != 888) %>% 
  mutate(SubNo = as.factor(SubNo),
         TrialValidity = as.factor(TrialValidity),
         StimNoise = as.factor(StimNoise),
         NonPred = as.factor(NonPred),
         Confidence = round(as.numeric(RawConfidence)),
         U = as.factor(U),
         Y = as.factor(Y),
         CueImg = as.factor(CueImg),
         FaceEmot = as.factor(FaceEmot),
         PredictResp = as.factor(PredictResp)) 
 

# Filter out rows where RawConfidence is 888 (indicating errors)
df <- df %>%
  filter(RawConfidence != 888, !is.na(RawConfidence))

# 2. Rename "PredictionRT" and "PredictResp" to "ResponseRT" and "FaceResponse"
df <- df %>%
  rename(ResponseRT = PredictionRT,
         FaceResponse = PredictResp)

# 3. Relabel StimNoise as "low noise" and "high noise"
df <- df %>%
  mutate(StimNoise = recode(StimNoise, `0` = "low noise", `1` = "high noise"))

# 4. Relabel TrialValidity as "Invalid" and "Valid"
df <- df %>%
  mutate(TrialValidity = recode(TrialValidity, `0` = "Invalid", `1` = "Valid"))

df <- df %>%
  mutate(FaceResponse = recode(FaceResponse, `0` = "Angry", `1` = "Happy"))

df <- df %>%
  mutate(FaceEmot = recode(FaceEmot, `0` = "Angry", `1` = "Happy"))

df <- df %>%
  mutate(TrialValidity2 = case_when(
    NonPred == 1 ~ "non-predictive",
    TRUE ~ as.character(TrialValidity)
  ))

# Convert the new TrialValidityNew variable to a factor
df <- df %>%
  mutate(TrialValidity2 = as.factor(TrialValidity2))

# Display the transformed data frame
print(df)