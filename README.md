# CWT fMRI Project - Confidence Weighting Task

## Overview

This repository contains the analysis pipeline for a Continuous Wavelet Transform (CWT) fMRI study investigating the **confidence weighting task**. The project examines how participants learn to predict emotional faces based on predictive cues in a reversal learning paradigm, with a focus on confidence, accuracy, and response time measures.

**📋 Experimental Design**: See [`docs/experimental_design.md`](docs/experimental_design.md) for detailed task description and stimulus structure, including visual diagram of the experimental design.

## Project Structure

```
CWT_fmri/
├── data/
│   ├── raw/                    # Original data files
│   │   ├── CWT_vmp1_master.csv (3.7MB, 53,592 trials)
│   │   ├── CWT_VMP1_master_table.mat
│   │   └── CWT_VMP1_master_table_extended.mat
│   └── processed/              # Processed data files
├── code/
│   ├── preprocessing/          # Data preparation scripts
│   │   └── 01_import_and_clean_data.R
│   ├── analysis/              # Statistical analysis scripts
│   │   ├── 01_basic_analysis_and_plots.R
│   │   ├── 02_run_glmm_main.R (current main analysis script)
│   │   ├── 02_validate_glmm.R (validation script)
│   │   ├── 03_run_anova_analyses.R
│   │   ├── 05_reversal_learning_plots.R
│   │   ├── theme_nature_neuroscience.R
│   │   └── backup/            # Archived previous versions
│   │       ├── 02_run_glmm_models_original.R
│   │       └── 02_run_glmm_models_debug.R
│   └── modeling/              # Computational modeling scripts
│       └── 04_run_computational_models.R
├── results/
│   ├── figures/               # Generated plots
│   │   ├── glmm_models/       # GLMM model plots
│   │   ├── learning_curves/   # Learning analysis plots
│   │   ├── confidence_analysis/ # Confidence-specific plots
│   │   ├── basic_analysis/    # Basic analysis plots
│   │   └── predictive_checks/ # Model validation plots
│   ├── tables/                # Output tables
│   └── models/                # Model results (.rds files)
├── docs/
│   ├── experimental_design.md # Task description and stimulus structure
│   ├── experimental_design.png
│   ├── glmm_report_simple.Rmd # Reproducible GLMM analysis report
│   ├── glmm_report.html # Generated HTML report with dark mode
│   ├── render_report.R # Script to regenerate the report
│   ├── dark-mode.css # Dark mode styling
│   ├── dark-mode-header.html # Dark mode toggle functionality
│   └── README.md # Documentation for the docs directory
└── README.md
```

## Experimental Design

### Task Overview
- **Participants**: 202 subjects
- **Trials**: 250 trials per subject (53,592 total trials)
- **Task**: Predict emotional faces (Happy/Angry) based on visual cues
- **Paradigm**: Reversal learning with changing cue:stimulus associations

### Cue:Stimulus Associations
- **Predictive blocks** (0.8 probability): Cue strongly predicts face emotion
- **Non-predictive blocks** (0.5 probability): Cue provides no predictive information
- **Antipredictive blocks** (0.2 probability): Cue predicts opposite face emotion

### Key Manipulations
- **Stimulus Noise**: High noise (ambiguous) vs low noise (clear) faces
- **Cue Validity**: Valid vs invalid vs non-predictive trials
- **Probability Reversals**: Learning blocks with changing contingencies

## Analysis Pipeline

The analysis is designed as a series of simple, standalone scripts that can be run in sequence:

### 1. Data Import and Cleaning
```r
source("code/preprocessing/01_import_and_clean_data.R")
```
- Loads raw CSV data (53,592 trials)
- Cleans and recodes variables
- Filters out error trials (RawConfidence == 888)
- Creates the main data frame `df` with 48,199 trials

### 2. Basic Analysis and Plots
```r
source("code/analysis/01_basic_analysis_and_plots.R")
```
- Creates descriptive statistics
- Generates basic plots (accuracy, RT, confidence distributions)
- Saves figures to `results/figures/basic_analysis/`

### 3. GLMM Analysis (Main Analysis)
```r
source("code/analysis/02_run_glmm_main.R")
```
- **Accuracy Model**: High noise trials only, predicts correct/incorrect responses
- **Choice Model**: High noise trials only, predicts Happy vs Angry choices
- **Response Time Model**: All trials, predicts response times
- **Confidence Model**: All trials, predicts confidence ratings (0-1 scale)

### 4. ANOVA Analysis
```r
source("code/analysis/03_run_anova_analyses.R")
```
- Runs traditional ANOVA analyses
- Provides additional statistical tests

### 5. Reversal Learning Analysis
```r
source("code/analysis/05_reversal_learning_plots.R")
```
- Analyzes learning dynamics around reversals
- Generates learning curve plots

### 6. Computational Modeling
```r
source("code/modeling/04_run_computational_models.R")
```
- Fits reinforcement learning models using hBayesDM
- Uses ug_delta model for uncertainty-guided learning
- Saves model results to `results/models/`

## GLMM Analysis Report

A comprehensive, reproducible report of the GLMM analysis is available in the `docs/` directory:

### Interactive HTML Report
- **File**: `docs/glmm_report.html`
- **Features**: 
  - Dynamic tables with model coefficients and fit statistics
  - Embedded figures from existing analysis
  - Dark mode toggle for comfortable viewing
  - Professional styling with interactive elements
  - Self-contained (no external dependencies)

### Reproducible Source
- **File**: `docs/glmm_report_simple.Rmd`
- **Features**:
  - Loads pre-estimated models from `results/models/`
  - Extracts coefficients and fit statistics programmatically
  - Embeds existing figures from `results/figures/glmm_models/`
  - Updates automatically when analysis changes

### Regeneration
To update the report after analysis changes:
```r
# From project root
cd docs
Rscript render_report.R
```

**View Online**: The report is hosted on GitHub Pages and can be viewed directly in your browser.

## Key Variables

### Experimental Design
- **SubNo**: Subject identifier (factor)
- **TrialNo**: Trial number within session (1-250)
- **TrialValidity**: Whether cue correctly predicts face emotion (0=Invalid, 1=Valid)
- **StimNoise**: Noise level in stimulus (0=low, 1=high)
- **TrialsSinceRev**: Number of trials since last reversal

### Stimulus Variables
- **CueImg**: Cue image type (0/1)
- **FaceEmot**: Actual face emotion (0=Angry, 1=Happy)
- **TrialValidity2**: Extended validity (Valid/Invalid/non-predictive)

### Response Variables
- **Accuracy**: Binary accuracy (0=miss, 1=hit)
- **ResponseRT**: Response time in seconds
- **RawConfidence**: Confidence rating (0-100, converted to 0-1)
- **FaceResponse**: Participant's choice (0=Angry, 1=Happy)

### Processed Variables
- **TrialsSinceRev_scaled**: Z-scored within subjects
- **TrialValidity2_numeric**: Recoded as 1/0/-1
- **FaceResponse_numeric**: Numeric version for modeling (0=Angry, 1=Happy)

## Quick Start Guide

### For New Users
1. **Clone the repository** and open in RStudio
2. **Install dependencies** (see Dependencies section below)
3. **Run the main analysis pipeline**:
   ```r
   source("code/preprocessing/01_import_and_clean_data.R")
   source("code/analysis/01_basic_analysis_and_plots.R")
   source("code/analysis/02_run_glmm_main.R")
   ```

### For Researchers Taking Over
1. **Review experimental design**: Read `docs/experimental_design.md`
2. **Check current results**: Browse `results/figures/` and `results/models/`
3. **Run validation**: Execute `code/analysis/02_validate_glmm.R`
4. **Modify analyses**: Edit scripts in `code/analysis/` (backup versions in `backup/`)

## Dependencies

### Required R Packages
```r
# Core analysis
library(tidyverse)
library(lme4)
library(lmerTest)
library(glmmTMB)

# Specialized models
library(ordinal)
library(DHARMa)

# Visualization and reporting
library(sjPlot)
library(sjmisc)
library(ggplot2)

# Computational modeling
library(hBayesDM)
```

### System Requirements
- **R** (version 4.0+ recommended)
- **RStudio** (for interactive development)
- **MATLAB** (optional, for additional `.mat` file processing)

## Output Files

### Generated Plots
- `results/figures/glmm_models/`: GLMM model predictions
- `results/figures/learning_curves/`: Learning dynamics
- `results/figures/confidence_analysis/`: Confidence-specific analyses
- `results/figures/basic_analysis/`: Descriptive statistics
- `results/figures/rl_models/`: Reinforcement learning model plots
- `results/figures/predictive_checks/`: Model validation

### Model Results
- `results/models/`: RDS files containing fitted models
- `results/models/glmm_model_summaries.txt`: Complete model summaries

### Tables
- `results/tables/`: CSV and HTML output tables

### Reports
- `docs/glmm_report.html`: Interactive HTML report with dark mode
- `docs/glmm_report_simple.Rmd`: Reproducible R Markdown source
- `docs/render_report.R`: Script to regenerate the report

## Notes

- **Script Safety**: Original scripts are preserved in `code/analysis/backup/`
- **White Backgrounds**: All plots use white backgrounds for publication
- **Modular Design**: Each script is standalone and can be run independently
- **Progress Tracking**: Scripts include progress messages for debugging
- **Documentation**: See `README.ai.md` for AI assistant context

## Citation

If you use this code in your research, please cite the original study and include a reference to this repository. 