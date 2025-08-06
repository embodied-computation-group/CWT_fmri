# CWT fMRI Task Details

## Overview
The CWT (Cue-Weighted Task) is a face emotion recognition task with predictive cues, designed for fMRI studies of predictive processing. Participants learn associations between visual cues and emotional faces, with dynamic probability changes and confidence ratings.

## Experimental Design

### Task Structure
1. **Cue Presentation** (0.5 sec): Visual cue (elephant/bicycle) predicts upcoming face emotion
2. **ISI** (2-3 sec): Variable inter-stimulus interval with fixation
3. **Face Presentation** (0.5 sec): Female face with varying emotional clarity
4. **Emotion Response** (2 sec limit): Choose "Angry" or "Happy"
5. **Confidence Rating** (3 sec limit): Rate confidence (0-100 scale)
6. **ITI** (1-2 sec): Variable inter-trial interval

### Trial Types
- **Valid trials**: Cue correctly predicts face emotion
- **Invalid trials**: Cue incorrectly predicts face emotion
- **Non-predictive trials**: Cue has no predictive relationship (P=0.5)

### Block Structure
- **Total trials**: 250 per participant (shortened from original 310)
- **Block types**: Predictive (P) and Unpredictive (U) blocks
- **Block lengths**: 
  - Long predictive: 40 ± 4 trials
  - Short predictive: 20 ± 4 trials  
  - Unpredictive: 10 ± 4 trials
- **Block sequence**: P-U-P-U-P-U-P-U-P (alternating)
- **Probability levels**: P(Happy|cue) = 0.25, 0.75, or 0.5

## MATLAB Log File Structure

### vars.cueProbabilityOutput Design Matrix
The raw MATLAB log files contain a design matrix (`vars[[18]]` in R) that encodes the complete experimental design:

| Column | Variable | Values | Description |
|--------|----------|--------|-------------|
| 1 | trial # | 1-264 | Sequential trial number |
| 2 | condition | [1,2,3,4,5] | **1** cue_0 valid, **2** cue_1 valid, **3** cue_0 invalid, **4** cue_1 invalid, **5** non-predictive |
| 3 | block type | [1,2,3] | **1** non-predictive, **2** predictive short, **3** predictive long |
| 4 | face gender | [0,1] | **0** male, **1** female |
| 5 | cue | [0,1] | **0** elephant, **1** bicycle |
| 6 | trial type | [1,2] | **1** Valid, **2** Invalid |
| 7 | desired prob | 0.18, 0.5, 0.82 | Target probability for cue-outcome association |
| 8 | effective prob | 0.18, 0.5, 0.82 | Actual implemented probability |
| 9 | block volatility | [0,1] | **1** volatile, **0** stable |
| 10 | outcome | [0,1] | **0** Angry, **1** Happy |
| 11 | predictive/non-predictive trial | [0,1] | Trial classification |
| 12 | cue0PredictionSequence | [0,1,2] | **0** NP, **1** cue_0→Happy, **2** cue_0→Angry |
| 13 | predictionTrialNext | [0,1] | **1** if prediction trial follows this trial's ITI |
| 14 | reversalBlocksSequence | - | Block sequence identifier |
| 15 | blockwiseTrialNumber | - | Trial number within current block |

### Key Experimental Features
- **Opposing Cues**: Within each block, cues are perfectly opposing (sum to 1.0)
- **Three Probability Levels**: 0.18/0.82, 0.5/0.5, 0.82/0.18
- **Block Transitions**: Reversals occur when desired_prob changes
- **Counterbalancing**: Block order, trial types, cues, and face genders are randomized

### Data Extraction in R
```r
# Extract true experimental design from MATLAB logs
design_matrix <- vars[[18]]  # This is the cueProbabilityOutput matrix

# Convert to data frame with correct column names
design_df <- data.frame(
  trial_no = design_matrix[, 1],
  condition = design_matrix[, 2],
  block_type = design_matrix[, 3],
  face_gender = design_matrix[, 4],
  cue = design_matrix[, 5],
  trial_type = design_matrix[, 6],
  desired_prob = design_matrix[, 7],
  effective_prob = design_matrix[, 8],
  block_volatility = design_matrix[, 9],
  outcome = design_matrix[, 10],
  predictive_trial = design_matrix[, 11],
  cue0_prediction = design_matrix[, 12],
  prediction_trial_next = design_matrix[, 13],
  reversal_blocks_sequence = design_matrix[, 14],
  blockwise_trial_number = design_matrix[, 15]
)
```

## Key Parameters

### Timing Parameters
```matlab
vars.CueT = 0.5;        % Cue duration (seconds)
vars.StimT = 0.5;       % Face duration (seconds)
vars.RespT = 2;          % Response time limit (seconds)
vars.ConfT = 3;          % Confidence time limit (seconds)
vars.ISI_min = 2;        % Minimum ISI (seconds)
vars.ISI_max = 3;        % Maximum ISI (seconds)
vars.ITI_min = 1;        % Minimum ITI (seconds)
vars.ITI_max = 2;        % Maximum ITI (seconds)
```

### Stimulus Parameters
```matlab
vars.StimSize = 9;                    % Stimulus size (DVA)
vars.PMFptsForStimuli = 0.05;         % 5% below/above threshold
vars.gaussNoiseVariance = 5;          % Noise variance for faces
```

### Response Parameters
```matlab
vars.InputDevice = 2;                 % 1=keyboard, 2=mouse
vars.ConfRating = 1;                  % 1=yes, 0=no
```

## Counterbalancing Strategy

### Randomization Functions
```matlab
function [arrayOut] = mixArray(arrayIn)
    randomorder = randperm(length(arrayIn));
    arrayOut = arrayIn(randomorder);
end
```

### Counterbalancing Elements
1. **Block Order**: `mixArray(probabilitiesArray)` randomizes predictive block order
2. **Trial Types**: `mixArray(trialvector)` randomizes valid/invalid trials within blocks
3. **Cue Assignment**: `mixArray(cueVectorThisBlock)` randomizes cue presentation
4. **Face Gender**: `mixArray(faceVectorThisBlock)` randomizes male/female faces
5. **Block Lengths**: Jittered with ±4 trials to prevent predictable timing
6. **Duplicate Prevention**: Logic to avoid sequential identical blocks

### Resulting Orders
- **Order A (Early)**: Reversals around trials 57-133
- **Order B (Late)**: Reversals around trials 65-137

## Face Stimulus Generation

### Individualized Stimuli
Each participant receives custom face morphs based on their threshold:
```matlab
[vars.noThreshFlag, thresh] = getParticipantThreshold(vars.subIDstring);
faceMorphsVals = [thresh - morphValsJump, thresh + morphValsJump];
meanFaceMorphs = round(faceMorphsVals);  % [angry, happy] values
```

### Noise Addition
```matlab
A_wnoise = ones(vars.NTrialsTotal/2, 2) .* meanFaceMorphs;
A_wnoise = A_wnoise + sqrt(vars.gaussNoiseVariance*2)*randn(size(A_wnoise));
vars.FaceMorphs = round(A_wnoise);
```

## Data Structure

### Key Variables
- **SubNo**: Subject identifier
- **TrialNo**: Trial number (1-250)
- **CueImg**: Cue type (0=elephant, 1=bicycle)
- **FaceEmot**: Actual face emotion (0=Angry, 1=Happy)
- **FaceResponse**: Participant's choice (0=Angry, 1=Happy)
- **Accuracy**: Binary accuracy (0=miss, 1=hit)
- **ResponseRT**: Response time in seconds
- **RawConfidence**: Confidence rating (0-100)
- **TrialsSinceRev**: Trials since last reversal (block boundary marker)
- **TrialValidity**: Valid/Invalid/Non-predictive
- **StimNoise**: High/Low noise faces

### Block Identification
```r
block_id = cumsum(TrialsSinceRev == 1)
```
- `TrialsSinceRev == 1` marks start of each new block
- `cumsum()` creates running block counter
- Each reversal (block boundary) increments block ID

## Analysis Approach

### Contingency Structure Plots
- **Blue line**: P(happy|Cue 0 - Elephant) 
- **Green line**: P(happy|Cue 1 - Bicycle)
- **Red vertical lines**: Reversal points (block boundaries)
- **Step-wise structure**: Probabilities constant within blocks, change at reversals
- **Opposing cues**: When one cue goes up, the other goes down (sum to 1.0)

### Learning Analysis
- **Peri-reversal learning**: ±20 trials around reversal points
- **Block-based learning**: Learning within stable blocks
- **Adaptation speed**: Trials to reach 75% accuracy after reversal

### Statistical Models
1. **Accuracy Model**: High noise trials only
2. **Choice Model**: High noise trials only  
3. **Response Time Model**: All trials
4. **Confidence Model**: All trials

## Key Findings

### Counterbalancing Success
- Two main counterbalanced orders identified
- Systematic differences in reversal timing
- Balanced probability levels across experiment

### Learning Dynamics
- Participants adapt to probability changes
- Learning curves show improvement after reversals
- Confidence calibration varies with stimulus noise

### Predictive Processing
- Cues influence face emotion perception
- Invalid trials show interference effects
- Non-predictive blocks show reduced cue influence

## File Structure
```
code/
├── task/                           # Original MATLAB task code
│   ├── main.m                     # Main experiment script
│   ├── loadParams.m               # Parameter loading
│   ├── setupTaskSequence/         # Task sequence setup
│   │   ├── setupCueProbabilities.m
│   │   ├── create_trials.m
│   │   └── jitter_values.m
│   └── helpers/                   # Helper functions
│       ├── mixArray.m             # Randomization function
│       ├── getResponse.m          # Response collection
│       ├── getConfidence.m        # Confidence rating
│       └── [other helper files]
├── preprocessing/
│   └── 01_import_and_clean_data.R
├── analysis/
│   ├── create_contingency_plots_corrected.R
│   ├── plot_true_contingencies_correct.R
│   ├── 02_run_glmm_main.R
│   └── theme_nature_neuroscience.R
└── modeling/
    └── 05_precision_weighted_rl_model.R

results/
├── figures/
│   └── basic_analysis/
│       ├── subject_reversal_plots/
│       └── true_contingency_plots/  # True experimental design plots
└── models/
```

## Notes
- Original design had 310 trials, shortened to 250
- Face stimuli are individualized per participant
- Counterbalancing creates systematic order differences
- Block structure follows P-U-P-U-P-U-P-U-P pattern
- Reversal points mark critical learning transitions
- **True contingencies** are extracted from `vars[[18]]` in MATLAB logs
- **Opposing cue design**: Within each block, cues are perfectly opposing (sum to 1.0)
- **Three probability levels**: 0.18/0.82, 0.5/0.5, 0.82/0.18 for predictive blocks 