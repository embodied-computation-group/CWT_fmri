# CWT fMRI Project

## Overview

This repository contains the analysis pipeline for a Continuous Wavelet Transform (CWT) fMRI study investigating predictive processing in face emotion recognition. The project examines how participants learn to predict emotional faces based on predictive cues, with a focus on confidence, accuracy, and response time measures.

## Project Structure

```
CWT_fmri/
├── data/
│   ├── raw/                    # Original data files
│   │   ├── CWT_vmp1_master.csv
│   │   ├── CWT_VMP1_master_table.mat
│   │   └── CWT_VMP1_master_table_extended.mat
│   └── processed/              # Processed data files
│       └── model_data.txt
├── code/
│   ├── preprocessing/          # Data preparation scripts
│   │   └── 01_import_and_clean_data.R
│   ├── analysis/              # Statistical analysis scripts
│   │   ├── 01_basic_analysis_and_plots.R
│   │   ├── 02_run_glmm_models.R
│   │   └── 03_run_anova_analyses.R
│   └── modeling/              # Computational modeling scripts
│       └── 04_run_computational_models.R
├── results/
│   ├── figures/               # Generated plots
│   ├── tables/                # Output tables
│   └── models/                # Model results
└── README.md
```

## Analysis Pipeline

The analysis is designed as a series of simple, standalone scripts that can be run in sequence:

### 1. Data Import and Cleaning
```r
source("code/preprocessing/01_import_and_clean_data.R")
```
- Loads raw CSV data
- Cleans and recodes variables
- Creates the main data frame `df`

### 2. Basic Analysis and Plots
```r
source("code/analysis/01_basic_analysis_and_plots.R")
```
- Creates descriptive statistics
- Generates basic plots (accuracy, RT, confidence distributions)
- Saves figures to `results/figures/`

### 3. GLMM Analysis
```r
source("code/analysis/02_run_glmm_models.R")
```
- Fits mixed-effects models for confidence, accuracy, and RT
- Uses ordered beta regression for confidence
- Uses binomial logistic regression for accuracy
- Uses gamma regression for response times

### 4. ANOVA Analysis
```r
source("code/analysis/03_run_anova_analyses.R")
```
- Runs traditional ANOVA analyses
- Provides additional statistical tests

### 5. Computational Modeling
```r
source("code/modeling/04_run_computational_models.R")
```
- Fits reinforcement learning models using hBayesDM
- Uses ug_delta model for uncertainty-guided learning
- Saves model results to `results/models/`

## Data Flow

### Raw Data → Processed Data
- **Input**: `data/raw/CWT_vmp1_master.csv` (53,593 trials)
- **Processing**: Variable recoding, filtering, factor conversion
- **Output**: Clean data frame `df` with 15 variables

### Processed Data → Analysis Results
- **Basic Analysis**: Descriptive stats and plots
- **GLMM Models**: Mixed-effects models for different outcomes
- **Computational Models**: Reinforcement learning models

## Key Variables

### Experimental Design
- **SubNo**: Subject identifier
- **TrialNo**: Trial number within session
- **TrialValidity**: Whether cue correctly predicts face emotion (0=Invalid, 1=Valid)
- **StimNoise**: Noise level in stimulus (0=low, 1=high)
- **TrialsSinceRev**: Number of trials since last reversal

### Stimulus Variables
- **CueImg**: Cue image type (0/1)
- **FaceEmot**: Actual face emotion (0=Angry, 1=Happy)

### Response Variables
- **Accuracy**: Binary accuracy (0=miss, 1=hit)
- **ResponseRT**: Response time in seconds
- **RawConfidence**: Confidence rating (0-1)
- **FaceResponse**: Participant's choice (0=Angry, 1=Happy)

## Usage

1. **Start with data import**: Run `01_import_and_clean_data.R`
2. **Basic exploration**: Run `01_basic_analysis_and_plots.R`
3. **Main analysis**: Run `02_run_glmm_models.R`
4. **Additional tests**: Run `03_run_anova_analyses.R`
5. **Computational modeling**: Run `04_run_computational_models.R`

## Dependencies

- **R** with packages: `tidyverse`, `lme4`, `lmerTest`, `ordinal`, `glmmTMB`, `DHARMa`, `sjPlot`, `sjmisc`, `hBayesDM`, `ggplot2`
- **MATLAB** for additional data processing (`.mat` files)

## Notes

- Each script is standalone and can be run independently
- Scripts are numbered for suggested execution order
- Results are automatically saved to appropriate directories
- All scripts include progress messages for easy debugging 