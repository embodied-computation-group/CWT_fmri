# GLMM Report Generator
# Loads pre-estimated models and existing figures to create HTML report
# 
# This script does NOT run new models - it only loads existing results
# and creates a comprehensive HTML report for GitHub viewing

library(tidyverse)
library(lme4)

# Set working directory to project root
setwd("../../")

# ============================================================================
# LOAD PRE-ESTIMATED MODELS
# ============================================================================

cat("Loading pre-estimated GLMM models...\n")

# Load model objects
accuracy_model <- readRDS("results/models/accuracy_model_simple.rds")
choice_model <- readRDS("results/models/choice_model_simple.rds")
rt_model <- readRDS("results/models/rt_model_simple.rds")
confidence_model <- readRDS("results/models/confidence_model_simple.rds")

# Load model summaries
model_summaries <- readLines("results/models/glmm_model_summaries.txt")

# ============================================================================
# CREATE MODEL FIT STATISTICS TABLE
# ============================================================================

cat("Creating model fit statistics...\n")

# Function to extract model fit statistics
extract_fit_stats <- function(model, model_name) {
  aic <- AIC(model)
  bic <- BIC(model)
  loglik <- logLik(model)
  
  # Get number of groups from random effects
  n_groups <- length(ranef(model)$SubNo$`(Intercept)`)
  
  data.frame(
    Model = model_name,
    AIC = round(aic, 2),
    BIC = round(bic, 2),
    LogLik = round(loglik, 2),
    N_Observations = nobs(model),
    N_Groups = n_groups,
    stringsAsFactors = FALSE
  )
}

# Create fit statistics table
fit_stats <- rbind(
  extract_fit_stats(accuracy_model, "Accuracy Model"),
  extract_fit_stats(choice_model, "Choice Model"),
  extract_fit_stats(rt_model, "Response Time Model"),
  extract_fit_stats(confidence_model, "Confidence Model")
)

# Print fit stats for debugging
cat("Fit statistics:\n")
print(fit_stats)

# ============================================================================
# CREATE HTML REPORT
# ============================================================================

cat("Generating HTML report...\n")

# Create HTML content
html_content <- paste0('
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CWT fMRI Study - GLMM Analysis Report</title>
    <style>
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 30px;
            border-left: 4px solid #3498db;
            padding-left: 15px;
        }
        h3 {
            color: #2c3e50;
            margin-top: 25px;
        }
        .model-section {
            background-color: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .figure-container {
            text-align: center;
            margin: 20px 0;
        }
        .figure-container img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .table-container {
            overflow-x: auto;
            margin: 20px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #3498db;
            color: white;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .significant {
            font-weight: bold;
            color: #e74c3c;
        }
        .summary-box {
            background-color: #e8f4fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #3498db;
        }
        .methodology {
            background-color: #fff3cd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #ffc107;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>CWT fMRI Study - GLMM Analysis Report</h1>
        
        <div class="summary-box">
            <h3>📊 Study Overview</h3>
            <p><strong>Participants:</strong> 202 subjects</p>
            <p><strong>Total Trials:</strong> 53,592 (48,199 after filtering)</p>
            <p><strong>Analysis:</strong> Four Generalized Linear Mixed Models examining predictive processing in emotion recognition</p>
        </div>

        <div class="methodology">
            <h3>🔬 Methodology</h3>
            <p><strong>Task:</strong> Participants predicted emotional faces (Happy/Angry) based on visual cues in a reversal learning paradigm.</p>
            <p><strong>Key Variables:</strong> Trial validity, stimulus noise, trials since reversal, face emotion</p>
            <p><strong>Models:</strong> Accuracy, Choice, Response Time, and Confidence models with subject-level random effects</p>
        </div>

        <h2>📈 Model Results</h2>
        
        <div class="model-section">
            <h3>1. Accuracy Model (High Noise Trials Only)</h3>
            <p><strong>Dependent Variable:</strong> Binary accuracy (correct/incorrect)</p>
            <p><strong>Key Finding:</strong> Trial validity significantly predicts accuracy (z = 5.03, p < 0.001)</p>
            <div class="figure-container">
                <img src="../../results/figures/glmm_models/glmm_accuracy_model.png" alt="Accuracy Model Predictions">
                <p><em>Figure 1: GLMM Accuracy Model - Trial Validity × Trials Since Reversal × Face Emotion</em></p>
            </div>
        </div>

        <div class="model-section">
            <h3>2. Choice Model (High Noise Trials Only)</h3>
            <p><strong>Dependent Variable:</strong> Face choice (Happy vs Angry)</p>
            <p><strong>Key Finding:</strong> Signaled face and actual face emotion strongly predict choices</p>
            <div class="figure-container">
                <img src="../../results/figures/glmm_models/glmm_choice_model.png" alt="Choice Model Predictions">
                <p><em>Figure 2: GLMM Choice Model - Signaled Face × Face Emotion × Trials Since Reversal</em></p>
            </div>
        </div>

        <div class="model-section">
            <h3>3. Response Time Model (All Trials)</h3>
            <p><strong>Dependent Variable:</strong> Response time (Gamma distribution)</p>
            <p><strong>Key Finding:</strong> High noise trials show significantly longer response times</p>
            <div class="figure-container">
                <img src="../../results/figures/glmm_models/glmm_rt_model.png" alt="Response Time Model Predictions">
                <p><em>Figure 3: GLMM Response Time Model - Stimulus Noise × Trial Validity × Trials Since Reversal</em></p>
            </div>
        </div>

        <div class="model-section">
            <h3>4. Confidence Model (All Trials)</h3>
            <p><strong>Dependent Variable:</strong> Confidence rating (0-1 scale, Beta distribution)</p>
            <p><strong>Key Finding:</strong> High noise trials show significantly lower confidence</p>
            <div class="figure-container">
                <img src="../../results/figures/glmm_models/glmm_confidence_model.png" alt="Confidence Model Predictions">
                <p><em>Figure 4: GLMM Confidence Model - Trial Validity × Stimulus Noise × Trials Since Reversal</em></p>
            </div>
        </div>

        <h2>📋 Model Fit Statistics</h2>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Model</th>
                        <th>AIC</th>
                        <th>BIC</th>
                        <th>Log Likelihood</th>
                        <th>N Observations</th>
                        <th>N Subjects</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Accuracy Model</td>
                        <td>', fit_stats$AIC[1], '</td>
                        <td>', fit_stats$BIC[1], '</td>
                        <td>', fit_stats$LogLik[1], '</td>
                        <td>', fit_stats$N_Observations[1], '</td>
                        <td>', fit_stats$N_Groups[1], '</td>
                    </tr>
                    <tr>
                        <td>Choice Model</td>
                        <td>', fit_stats$AIC[2], '</td>
                        <td>', fit_stats$BIC[2], '</td>
                        <td>', fit_stats$LogLik[2], '</td>
                        <td>', fit_stats$N_Observations[2], '</td>
                        <td>', fit_stats$N_Groups[2], '</td>
                    </tr>
                    <tr>
                        <td>Response Time Model</td>
                        <td>', fit_stats$AIC[3], '</td>
                        <td>', fit_stats$BIC[3], '</td>
                        <td>', fit_stats$LogLik[3], '</td>
                        <td>', fit_stats$N_Observations[3], '</td>
                        <td>', fit_stats$N_Groups[3], '</td>
                    </tr>
                    <tr>
                        <td>Confidence Model</td>
                        <td>', fit_stats$AIC[4], '</td>
                        <td>', fit_stats$BIC[4], '</td>
                        <td>', fit_stats$LogLik[4], '</td>
                        <td>', fit_stats$N_Observations[4], '</td>
                        <td>', fit_stats$N_Groups[4], '</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h2>🔍 Key Findings Summary</h2>
        <div class="summary-box">
            <h3>Main Effects</h3>
            <ul>
                <li><strong>Trial Validity:</strong> Valid trials show higher accuracy and confidence</li>
                <li><strong>Stimulus Noise:</strong> High noise trials show longer RTs and lower confidence</li>
                <li><strong>Face Emotion:</strong> Happy faces show different patterns than angry faces</li>
                <li><strong>Learning:</strong> Trials since reversal show some learning effects</li>
            </ul>
            
            <h3>Interaction Effects</h3>
            <ul>
                <li><strong>Validity × Learning:</strong> Trial validity effects change with learning</li>
                <li><strong>Noise × Validity:</strong> Noise effects interact with trial validity</li>
                <li><strong>Emotion × Validity:</strong> Different patterns for happy vs angry faces</li>
            </ul>
        </div>

        <h2>📄 Complete Model Summaries</h2>
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; font-family: monospace; white-space: pre-wrap; font-size: 12px;">
', paste(model_summaries, collapse = "\n"), '
        </div>

        <div style="margin-top: 40px; padding: 20px; background-color: #e8f4fd; border-radius: 8px; text-align: center;">
            <p><strong>Report generated on:</strong> ', Sys.Date(), '</p>
            <p><strong>Analysis pipeline:</strong> CWT fMRI GLMM Analysis</p>
            <p><em>This report was generated programmatically from pre-estimated models and existing figures.</em></p>
        </div>
    </div>
</body>
</html>
')

# Debug: Check if html_content was created
cat("HTML content length:", nchar(html_content), "\n")

# Write HTML file with absolute path
output_file <- "reports/glmms/glmm_analysis_report.html"
cat("Writing HTML file to:", output_file, "\n")
writeLines(html_content, output_file)

# Check if file was created
if (file.exists(output_file)) {
  cat("✅ HTML report generated successfully:", output_file, "\n")
  cat("File size:", file.size(output_file), "bytes\n")
} else {
  cat("❌ Error: HTML file was not created\n")
}

cat("📊 Report includes:\n")
cat("   - 4 GLMM model summaries\n")
cat("   - Model fit statistics\n")
cat("   - All existing figures\n")
cat("   - Key findings summary\n")
cat("   - Complete model output\n") 