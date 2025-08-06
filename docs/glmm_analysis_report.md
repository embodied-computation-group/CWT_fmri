# CWT fMRI Study - GLMM Analysis Report

*Predictive Processing in Emotion Recognition*

---

## Study Overview

This report presents the results of four Generalized Linear Mixed Models (GLMMs) examining predictive processing in emotion recognition using a confidence weighting task.

**Participants:** 202 subjects  
**Total Trials:** 53,592 (48,199 after filtering)  
**Task:** Predict emotional faces (Happy/Angry) based on visual cues in a reversal learning paradigm

### Experimental Design

- **Trial Validity:** Valid vs Invalid vs Non-predictive trials
- **Stimulus Noise:** High noise (ambiguous) vs Low noise (clear) faces
- **Learning:** Trials since reversal (learning dynamics)
- **Face Emotion:** Happy vs Angry faces

---

## Model Results

### 1. Accuracy Model (High Noise Trials Only)

**Research Question:** How does trial validity and learning affect accuracy in high-noise trials?

**Key Findings:**
- ✅ **Trial Validity:** Valid trials show significantly higher accuracy (z = 5.03, p < 0.001)
- ❌ **Face Emotion:** Happy faces show lower accuracy than angry faces (z = -7.14, p < 0.001)
- 🔄 **Learning:** Trial validity effects change with learning (interaction: z = 2.18, p = 0.030)

**Interpretation:** Participants are more accurate when cues correctly predict the face emotion, but this effect changes over time as they learn the task contingencies.

![Accuracy Model Predictions](results/figures/glmm_models/glmm_accuracy_model.png)

---

### 2. Choice Model (High Noise Trials Only)

**Research Question:** How do signaled faces and actual emotions influence choice behavior?

**Key Findings:**
- 🎯 **Signaled Face:** Angry signaled faces reduce choice of angry (z = -5.23, p < 0.001)
- 😊 **Actual Emotion:** Happy faces strongly predict happy choices (z = 36.38, p < 0.001)
- 🔄 **Learning:** Learning effects interact with signaled face (z = -4.10, p < 0.001)

**Interpretation:** Participants use predictive cues to guide their choices, but also respond strongly to the actual face emotion. Learning modulates these effects.

![Choice Model Predictions](results/figures/glmm_models/glmm_choice_model.png)

---

### 3. Response Time Model (All Trials)

**Research Question:** How do stimulus noise and trial validity affect response times?

**Key Findings:**
- ⏱️ **Stimulus Noise:** High noise trials show significantly longer RTs (z = 70.35, p < 0.001)
- ⚡ **Trial Validity:** Invalid trials show shorter RTs (z = -5.87, p < 0.001)
- 🔄 **Learning:** Validity effects change with learning (interaction: z = -3.26, p = 0.001)

**Interpretation:** Task difficulty (noise) increases response times, while invalid trials (surprising outcomes) lead to faster responses, possibly due to surprise or reduced confidence.

![Response Time Model Predictions](results/figures/glmm_models/glmm_rt_model.png)

---

### 4. Confidence Model (All Trials)

**Research Question:** How do trial validity and stimulus noise affect confidence ratings?

**Key Findings:**
- 😰 **Stimulus Noise:** High noise trials show significantly lower confidence (z = -127.10, p < 0.001)
- 💪 **Trial Validity:** Valid trials show higher confidence (z = 2.60, p = 0.009)
- 😊 **Face Emotion:** Happy faces show higher confidence (z = 18.35, p < 0.001)
- 🔄 **Learning:** Validity effects change with learning (interaction: z = 3.50, p < 0.001)

**Interpretation:** Participants are less confident when faces are ambiguous (high noise) and more confident when cues correctly predict outcomes. Happy faces generally elicit higher confidence.

![Confidence Model Predictions](results/figures/glmm_models/glmm_confidence_model.png)

---

## Key Findings Summary

### Main Effects

| Variable | Accuracy | Choice | Response Time | Confidence |
|----------|----------|--------|---------------|------------|
| **Trial Validity** | ✅ Higher for valid | ✅ Influences choice | ⚡ Faster for invalid | 💪 Higher for valid |
| **Stimulus Noise** | - | - | ⏱️ Slower for high noise | 😰 Lower for high noise |
| **Face Emotion** | ❌ Lower for happy | 😊 Strong preference | - | 😊 Higher for happy |
| **Learning** | 🔄 Modulates validity | 🔄 Modulates choice | 🔄 Modulates validity | 🔄 Modulates validity |

### Interaction Effects

- **Validity × Learning:** Trial validity effects change with learning across all models
- **Noise × Validity:** Noise effects interact with trial validity in RT and confidence
- **Emotion × Validity:** Different patterns for happy vs angry faces

---

## Model Fit Statistics

| Model | AIC | BIC | Log Likelihood | N Observations | N Subjects |
|-------|-----|-----|----------------|----------------|------------|
| **Accuracy Model** | 28,276 | 28,349 | -14,129 | 23,706 | 201 |
| **Choice Model** | 24,993 | 25,066 | -12,488 | 23,706 | 201 |
| **Response Time Model** | 22,314 | 22,401 | -11,147 | 48,198 | 201 |
| **Confidence Model** | 35,522 | 35,636 | -17,748 | 48,198 | 201 |

---

## Conclusions

This analysis reveals robust evidence for **predictive processing** in emotion recognition:

1. **Trial validity** consistently affects all dependent measures
2. **Stimulus noise** primarily affects response times and confidence
3. **Learning effects** are evident across all models
4. **Face emotion** shows consistent effects on choice and confidence

The results support the hypothesis that participants use **predictive cues** to guide their responses, with **learning effects** modulating these relationships over time.

---

*Report generated on August 6, 2024*  
*Analysis: CWT fMRI GLMM Study* 