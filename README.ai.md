# CWT fMRI Project - AI Session Context

## Project Overview

This repository contains the analysis pipeline for a Continuous Wavelet Transform (CWT) fMRI study investigating the confidence weighting task. The project examines how participants learn to predict emotional faces based on predictive cues, with a focus on confidence, accuracy, and response time measures in a reversal learning paradigm.

## Key Paths and Directory Structure

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
│   ├── figures/               # Generated plots (many PNG files)
│   │   ├── glmm_models/       # GLMM model plots
│   │   ├── learning_curves/   # Learning analysis plots
│   │   ├── confidence_analysis/ # Confidence-specific plots
│   │   ├── basic_analysis/    # Basic analysis plots
│   │   ├── rl_models/         # Reinforcement learning model plots
│   │   └── predictive_checks/ # Model validation plots
│   ├── tables/                # Output tables
│   └── models/                # Model results (.rds files)
├── docs/
│   ├── experimental_design.md # Task description and stimulus structure
│   └── experimental_design.png
└── README.md                  # Main project documentation
```

## User Preferences

**CRITICAL: Always follow these preferences:**

1. **Figure Styling**: Always print figures with white background
   ```r
   # Use this for all plots:
   + theme_minimal() + theme(panel.background = element_rect(fill = "white"))
   ```

2. **Code Safety**: Do NOT overwrite existing code without asking
   - Always ask before modifying existing scripts
   - Create new files with descriptive names (e.g., `_simple`, `_debug`, `_v2`)
   - Preserve original files

3. **File Naming**: Use descriptive suffixes for new files
   - `_simple` for simplified versions
   - `_debug` for debugging versions
   - `_v2`, `_v3` for iterations

4. **Script Clarity**: Prioritize simplicity and readability over elegance
   - Write code that PhD students can easily adapt and use
   - Use clear, descriptive variable names
   - Add helpful comments explaining each step
   - Keep functions simple and focused
   - Avoid overly complex one-liners or nested operations
   - Use explicit steps rather than clever shortcuts
   - Structure scripts with clear sections and headers

5. **Plotting Style**: Use Nature Neuroscience theme consistently
   - All plots use `theme_nature_neuroscience()` from `code/analysis/theme_nature_neuroscience.R`
   - White backgrounds with clean, professional appearance
   - Consistent color palette for experimental conditions
   - Publication-ready formatting

## Data Dictionary

### Raw Data Variables (CWT_vmp1_master.csv)
- **SubNo**: Subject identifier (factor)
- **TrialNo**: Trial number within session (1-250)
- **NonPred**: Non-predictive trial indicator (0/1)
- **TrialValidity**: Whether cue correctly predicts face emotion (0=Invalid, 1=Valid)
- **StimNoise**: Noise level in stimulus (0=low, 1=high)
- **Accuracy**: Binary accuracy (0=miss, 1=hit)
- **PredictionRT**: Response time in seconds (renamed to ResponseRT)
- **RawConfidence**: Confidence rating (0-100, converted to 0-1)
- **ConfidenceRT**: Time to make confidence rating
- **TrialsSinceRev**: Number of trials since last reversal
- **U**: Uncertainty indicator (0/1)
- **Y**: Outcome indicator (0/1)
- **CueImg**: Cue image type (0/1)
- **FaceEmot**: Actual face emotion (0=Angry, 1=Happy)
- **PredictResp**: Participant's choice (0=Angry, 1=Happy, renamed to FaceResponse)

### Processed Data Variables (after preprocessing)
- **TrialValidity2**: Extended validity (Valid/Invalid/non-predictive)
- **StimNoise**: Recoded as "low noise"/"high noise"
- **FaceResponse**: Recoded as "Angry"/"Happy"
- **FaceEmot**: Recoded as "Angry"/"Happy"
- **TrialsSinceRev_scaled**: Z-scored within subjects
- **TrialValidity2_numeric**: Recoded as 1/0/-1
- **FaceResponse_numeric**: Numeric version for modeling (0=Angry, 1=Happy)

## Experimental Context

### Task Design
- **Participants**: 202 subjects
- **Trials**: 250 trials per subject
- **Total Data**: 53,592 trials (48,199 after filtering)

### Stimulus Structure
- **Face Stimuli**: Grayscale female faces with varying emotional clarity
- **Cues**: Visual cues (elephant, bicycle) predictive of face emotion
- **Noise Levels**: High noise (ambiguous) vs low noise (clear) faces
- **Probability Structure**: Three types of cue:stimulus associations:
  - **Predictive blocks** (0.8 probability): Cue strongly predicts face emotion
  - **Non-predictive blocks** (0.5 probability): Cue provides no predictive information
  - **Antipredictive blocks** (0.2 probability): Cue predicts opposite face emotion

### Key Experimental Manipulations
1. **Stimulus Noise**: Affects task difficulty and confidence calibration
2. **Cue Validity**: Valid vs invalid vs non-predictive trials
3. **Probability Reversals**: Learning blocks with changing contingencies

### Behavioral Measures
- **Accuracy**: Binary correct/incorrect responses
- **Response Time**: Time to make emotion choice
- **Confidence**: Self-reported confidence rating (0-100)
- **Choice**: Angry vs Happy selection

## Current Working Scripts

### Main Analysis Pipeline
1. **Data Import**: `code/preprocessing/01_import_and_clean_data.R`
2. **Basic Analysis**: `code/analysis/01_basic_analysis_and_plots.R`
3. **GLMM Analysis**: `code/analysis/02_run_glmm_main.R` (CURRENT MAIN SCRIPT)
4. **ANOVA Analysis**: `code/analysis/03_run_anova_analyses.R`
5. **Computational Modeling**: `code/modeling/04_run_computational_models.R`

## Technical Notes

### R Packages Required
```r
library(lme4)
library(lmerTest)
library(ordinal)
library(glmmTMB)
library(tidyverse)
library(DHARMa)
library(sjPlot)
library(sjmisc)
```

### Data Preprocessing Steps
1. Filter out `RawConfidence == 888` (errors)
2. Convert confidence to 0-1 scale
3. Recode categorical variables
4. Scale `TrialsSinceRev` within subjects
5. Create numeric versions for modeling

## File Naming Conventions and Modular Structure

### Script Naming and Execution Flow
- `01_`, `02_`, etc.: Execution order in analysis pipeline
- `_simple`: Simplified versions of complex scripts
- `_debug`: Debugging versions with additional diagnostics
- `_v2`, `_v3`: Iterations of the same script
- `_main`: Primary analysis scripts (e.g., `02_run_glmm_main.R`)

### Modular Subdirectory Structure
```
code/
├── preprocessing/          # Data preparation (01_*)
├── analysis/             # Statistical analysis (02_*, 03_*, 05_*)
│   └── backup/          # Archived script versions
└── modeling/            # Computational modeling (04_*)

results/
├── figures/             # Generated plots
│   ├── glmm_models/    # GLMM-specific plots
│   ├── learning_curves/ # Learning analysis plots
│   └── confidence_analysis/ # Confidence-specific plots
├── models/              # Model objects (.rds files)
└── tables/              # Output tables (.csv, .html)
```

### Script-to-Output Flow
1. **Data Import** (`01_import_and_clean_data.R`)
   → Creates processed data in `data/processed/`

2. **Basic Analysis** (`01_basic_analysis_and_plots.R`)
   → Saves plots to `results/figures/`
   → Saves tables to `results/tables/`

3. **GLMM Analysis** (`02_run_glmm_main.R`)
   → Saves models to `results/models/glmm_*.rds`
   → Saves plots to `results/figures/glmm_models/`
   → Saves summaries to `results/models/glmm_model_summaries.txt`

4. **ANOVA Analysis** (`03_run_anova_analyses.R`)
   → Saves results to `results/tables/`
   → Saves plots to `results/figures/`

5. **Computational Modeling** (`04_run_computational_models.R`)
   → Saves model fits to `results/models/`
   → Saves plots to `results/figures/`

### Output File Naming Conventions
- **Plots**: Descriptive names with analysis type prefix (e.g., `glmm_accuracy_model.png`)
- **Models**: Analysis type + model name (e.g., `accuracy_model_simple.rds`)
- **Tables**: Analysis type + content description (e.g., `glmm_model_summaries.txt`)
- **Backup files**: Original name + version suffix in `backup/` subdirectory

## Session Context

This project focuses on the confidence weighting task in emotion recognition using a reversal learning paradigm. The current working GLMM script is `02_run_glmm_main.R` which provides a clean, validated analysis pipeline with simple random effects structure and comprehensive visualizations.

When working on this project, always prioritize:
1. User preferences (white backgrounds, no overwriting, script clarity)
2. Data validation and preprocessing
3. Model convergence and diagnostics
4. Clear documentation and reproducibility
5. **Code simplicity and readability** - write for PhD students to easily understand and adapt 