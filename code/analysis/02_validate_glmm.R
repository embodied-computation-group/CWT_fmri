library(lme4)
library(lmerTest)
library(ordinal)
library(glmmTMB)
library(tidyverse)
library(DHARMa)
library(sjPlot)
library(sjmisc)

cat("=== GLMM Script Validation ===\n")

# Test 1: Load data
cat("Test 1: Loading data...\n")
tryCatch({
  source("code/preprocessing/01_import_and_clean_data.R")
  cat("✓ Data loaded successfully\n")
  cat("  - Data frame dimensions:", dim(df), "\n")
  cat("  - Number of subjects:", length(unique(df$SubNo)), "\n")
  cat("  - Number of trials:", nrow(df), "\n")
}, error = function(e) {
  cat("✗ Error loading data:", e$message, "\n")
  stop("Data loading failed")
})

# Test 2: Data preprocessing
cat("\nTest 2: Data preprocessing...\n")
tryCatch({
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
  
  cat("✓ Data preprocessing completed\n")
  cat("  - RawConfidence range:", range(df$RawConfidence, na.rm=TRUE), "\n")
  cat("  - Accuracy levels:", levels(df$Accuracy), "\n")
  cat("  - TrialValidity2_numeric range:", range(df$TrialValidity2_numeric, na.rm=TRUE), "\n")
}, error = function(e) {
  cat("✗ Error in data preprocessing:", e$message, "\n")
  stop("Data preprocessing failed")
})

# Test 3: Simple model fitting
cat("\nTest 3: Simple model fitting...\n")
tryCatch({
  # Simple confidence model
  simple_conf_model <- glmmTMB(RawConfidence ~ TrialNo + (1|SubNo),
                               data = df,
                               family = ordbeta(),
                               start = list(psi = c(0, 1)))
  cat("✓ Simple confidence model fitted successfully\n")
  print(summary(simple_conf_model))
}, error = function(e) {
  cat("✗ Error in simple model fitting:", e$message, "\n")
})

# Test 4: Check for missing packages
cat("\nTest 4: Package availability...\n")
required_packages <- c("lme4", "lmerTest", "ordinal", "glmmTMB", "tidyverse", "DHARMa", "sjPlot", "sjmisc")
for(pkg in required_packages) {
  if(require(pkg, character.only = TRUE)) {
    cat("✓", pkg, "loaded successfully\n")
  } else {
    cat("✗", pkg, "not available\n")
  }
}

# Test 5: Data structure validation
cat("\nTest 5: Data structure validation...\n")
cat("  - Variables in df:", paste(names(df), collapse=", "), "\n")
cat("  - Missing values summary:\n")
print(colSums(is.na(df)))

# Test 6: Variable ranges
cat("\nTest 6: Variable ranges...\n")
numeric_vars <- c("TrialNo", "ResponseRT", "RawConfidence", "TrialsSinceRev")
for(var in numeric_vars) {
  if(var %in% names(df)) {
    cat("  -", var, "range:", range(df[[var]], na.rm=TRUE), "\n")
  }
}

cat("\n=== Validation Complete ===\n") 