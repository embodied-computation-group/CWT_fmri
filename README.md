# CWT fMRI Project

## Overview

This repository contains the analysis pipeline for a Continuous Wavelet Transform (CWT) fMRI study investigating predictive processing in face emotion recognition. The project examines how participants learn to predict emotional faces based on predictive cues, with a focus on confidence, accuracy, and response time measures.

## Project Structure

```
CWT_fmri/
├── CWT_fmri.Rproj          # RStudio project file
├── CWT_vmp1_master.csv     # Main behavioral dataset (53,593 trials)
├── CWT_VMP1_master_table.mat           # MATLAB format data
├── CWT_VMP1_master_table_extended.mat  # Extended MATLAB format data
├── model_data.txt           # Processed data for computational modeling (48,200 trials)
├── getdata.R               # Data preprocessing and cleaning script
├── glmer_analysis.R        # Main statistical analysis script
├── run_anovas.R           # ANOVA analyses
├── computational_modeling.R # Reinforcement learning models (hBayesDM)
└── .Rhistory              # R command history
```

## Data Flow

### 1. Raw Data Sources
- **Primary Dataset**: `CWT_vmp1_master.csv` (53,593 trials)
  - Contains behavioral data from face emotion recognition task
  - Includes 15 variables: SubNo, TrialNo, NonPred, TrialValidity, StimNoise, Accuracy, PredictionRT, RawConfidence, ConfidenceRT, TrialsSinceRev, U, Y, CueImg, FaceEmot, PredictResp

### 2. Data Preprocessing (`getdata.R`)
The preprocessing pipeline performs the following transformations:

- **Data Cleaning**:
  - Filters out trials with PredictResp = 888 (error trials)
  - Removes trials with RawConfidence = 888 (error trials)
  - Converts categorical variables to factors

- **Variable Recoding**:
  - `StimNoise`: 0 → "low noise", 1 → "high noise"
  - `TrialValidity`: 0 → "Invalid", 1 → "Valid"
  - `FaceResponse`: 0 → "Angry", 1 → "Happy"
  - `FaceEmot`: 0 → "Angry", 1 → "Happy"
  - `TrialValidity2`: Creates "non-predictive" category for NonPred = 1 trials

- **Variable Renaming**:
  - `PredictionRT` → `ResponseRT`
  - `PredictResp` → `FaceResponse`

### 3. Statistical Analysis (`glmer_analysis.R`)

The main analysis script implements several mixed-effects models:

#### Confidence Models
- **Ordered Beta Regression** for confidence ratings (0-1 scale)
- Models include random effects for subjects and various fixed effects
- Key predictors: TrialValidity2, StimNoise, TrialsSinceRev, Accuracy

#### Accuracy Models
- **Binomial Logistic Regression** for binary accuracy outcomes
- Predictors: TrialValidity2, StimNoise, FaceEmot, CueImg
- Random effects for subjects

#### Response Time Models
- **Gamma Regression** for response times
- Predictors: StimNoise, TrialValidity2
- Random effects for subjects

#### Choice Models
- **Binomial Logistic Regression** for face response choices
- Focuses on high noise trials only
- Predictors: SignaledFace, FaceEmot, TrialsSinceRev

### 4. Computational Modeling (`computational_modeling.R`)
- Implements reinforcement learning models using `hBayesDM`
- Creates `model_data.txt` for computational modeling
- Uses `ug_delta` model for uncertainty-guided learning
- Includes comprehensive data preparation and model fitting functions
- Provides parameter interpretation and model diagnostics

## Key Variables

### Experimental Design Variables
- **SubNo**: Subject identifier
- **TrialNo**: Trial number within session
- **TrialValidity**: Whether the cue correctly predicts the face emotion (0=Invalid, 1=Valid)
- **StimNoise**: Noise level in stimulus presentation (0=low, 1=high)
- **NonPred**: Non-predictive trials (1=non-predictive)
- **TrialsSinceRev**: Number of trials since last reversal

### Stimulus Variables
- **CueImg**: Cue image type (0/1)
- **FaceEmot**: Actual face emotion presented (0=Angry, 1=Happy)
- **U, Y**: Additional experimental variables

### Response Variables
- **Accuracy**: Binary accuracy (0=miss, 1=hit)
- **ResponseRT**: Response time in seconds
- **RawConfidence**: Raw confidence rating (0-100, scaled to 0-1)
- **FaceResponse**: Participant's face emotion choice (0=Angry, 1=Happy)

## Analysis Highlights

### 1. Confidence Analysis
- Uses ordered beta regression to model confidence ratings
- Examines effects of trial validity, stimulus noise, and learning over time
- Includes subject-level random effects for individual differences

### 2. Accuracy Analysis
- Models binary accuracy outcomes
- Tests effects of cue validity, stimulus noise, and face emotion
- Accounts for subject-level variability

### 3. Response Time Analysis
- Gamma regression for positively skewed RT distributions
- Examines effects of stimulus noise and trial validity
- Includes subject-level random effects

### 4. Choice Analysis
- Focuses on high noise trials for choice modeling
- Tests how signaled vs. shown faces influence choices
- Examines learning effects over trials since reversal

## Technical Details

### Software Dependencies
- **R** with packages: `lme4`, `lmerTest`, `ordinal`, `glmmTMB`, `tidyverse`, `DHARMa`, `sjPlot`, `sjmisc`, `hBayesDM`
- **MATLAB** for additional data processing (`.mat` files)

### Model Specifications
- **Mixed-effects models** with subject-level random effects
- **Ordered beta regression** for bounded confidence data
- **Gamma regression** for response times
- **Binomial logistic regression** for accuracy and choice data

### Data Quality
- Original dataset: 53,593 trials
- Processed dataset: 48,200 trials (after filtering)
- Multiple subjects with repeated measures design

## Research Context

This project appears to investigate:
1. **Predictive processing** in face emotion recognition
2. **Learning dynamics** over trial sequences
3. **Confidence calibration** in uncertain environments
4. **Response adaptation** to changing stimulus statistics

The experimental design suggests a reversal learning paradigm where participants must adapt to changing cue-face contingencies, with particular focus on how confidence and accuracy change as a function of stimulus noise and cue validity.

## Usage

1. **Data Preprocessing**: Run `getdata.R` to clean and prepare the dataset
2. **Main Analysis**: Execute `glmer_analysis.R` for statistical modeling
3. **Additional Analyses**: Use `run_anovas.R` for ANOVA-based analyses
4. **Computational Modeling**: Run `computational_modeling.R` for reinforcement learning models

## Notes

- The repository contains both R and MATLAB data formats
- Some analysis files are marked as "trash" but contain useful modeling approaches
- The project uses modern mixed-effects modeling approaches for hierarchical data
- Confidence ratings are modeled using ordered beta regression, appropriate for bounded continuous data 