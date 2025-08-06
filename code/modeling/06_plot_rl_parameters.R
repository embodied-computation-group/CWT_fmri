# -----------------------------------------------------------------------------
# COMPANION SCRIPT: PLOT RL MODEL PARAMETERS
# -----------------------------------------------------------------------------
#
# This script creates comprehensive visualizations of the precision-weighted
# RL model parameters (alpha, beta, omega) including:
# - Boxplots showing distribution and median values
# - Individual parameter estimates
# - Statistical comparisons against zero
# - Publication-ready Nature Neuroscience style plots
#
# -----------------------------------------------------------------------------

# 1. LOAD NECESSARY LIBRARIES
# -----------------------------------------------------------------------------
library(tidyverse)
library(ggplot2)
library(dplyr)
library(tidyr)

# Load custom Nature Neuroscience theme
source("code/analysis/theme_nature_neuroscience.R")

cat("=== RL Model Parameter Visualization ===\n")

# 2. LOAD RL MODEL RESULTS
# -----------------------------------------------------------------------------
cat("Loading RL model results...\n")

# Check if results file exists
if (!file.exists("results/models/rl_model_results.csv")) {
  cat("Error: RL model results not found. Please run the RL model first.\n")
  cat("Run: Rscript code/modeling/05_precision_weighted_rl_model.R\n")
  stop("RL model results not found")
}

# Load results
rl_results <- read.csv("results/models/rl_model_results.csv")

# Filter for successful fits only
successful_fits <- rl_results %>%
  filter(!is.na(alpha) & convergence == 0)

cat("Loaded", nrow(successful_fits), "successful model fits out of", nrow(rl_results), "total subjects\n\n")

# 3. CREATE COMPREHENSIVE PARAMETER PLOTS
# -----------------------------------------------------------------------------
cat("Creating parameter visualizations...\n")

# Prepare data for plotting
plot_data <- successful_fits %>%
  select(SubNo, alpha, beta, omega) %>%
  pivot_longer(cols = c(alpha, beta, omega), 
               names_to = "parameter", 
               values_to = "value") %>%
  mutate(
    parameter = factor(parameter, 
                      levels = c("alpha", "beta", "omega"),
                      labels = c("α (Learning Rate)", "β (Inverse Temperature)", "ω (Precision Weight)")),
    parameter_short = factor(parameter,
                           levels = c("α (Learning Rate)", "β (Inverse Temperature)", "ω (Precision Weight)"),
                           labels = c("α", "β", "ω"))
  )

# 4. CREATE BOXPLOT WITH INDIVIDUAL POINTS
# -----------------------------------------------------------------------------
cat("Creating boxplot with individual estimates...\n")

# Calculate summary statistics for each parameter
param_summary <- plot_data %>%
  group_by(parameter) %>%
  summarise(
    median_val = median(value, na.rm = TRUE),
    mean_val = mean(value, na.rm = TRUE),
    sd_val = sd(value, na.rm = TRUE),
    n = n(),
    .groups = 'drop'
  )

# Create the main boxplot
p1 <- ggplot(plot_data, aes(x = parameter_short, y = value)) +
  # Add individual points with jitter
  geom_jitter(width = 0.2, alpha = 0.4, size = 1, color = "steelblue") +
  # Add boxplot
  geom_boxplot(fill = "lightblue", alpha = 0.7, outlier.shape = NA) +
  # Add median line
  stat_summary(fun = median, geom = "point", shape = 23, size = 3, fill = "red") +
  # Add zero reference line
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  # Customize appearance
  labs(
    title = "Precision-Weighted RL Model Parameters",
    subtitle = paste("N =", nrow(successful_fits), "subjects with successful model fits"),
    x = "Parameter",
    y = "Parameter Value",
    caption = "Red diamond = median, Dashed line = zero reference"
  ) +
  theme_nature_neuroscience() +
  theme(
    axis.text.x = element_text(size = 12, face = "bold"),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11)
  )

# 5. CREATE SEPARATE PARAMETER PLOTS
# -----------------------------------------------------------------------------
cat("Creating individual parameter plots...\n")

# Alpha (Learning Rate) plot
p_alpha <- ggplot(filter(plot_data, parameter == "α (Learning Rate)"), 
                  aes(x = parameter_short, y = value)) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1.5, color = "steelblue") +
  geom_boxplot(fill = "lightblue", alpha = 0.7, outlier.shape = NA) +
  stat_summary(fun = median, geom = "point", shape = 23, size = 4, fill = "red") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  labs(
    title = "Learning Rate (α)",
    subtitle = paste("Median =", round(param_summary$median_val[1], 3), 
                    "| Mean =", round(param_summary$mean_val[1], 3)),
    x = NULL,
    y = "Learning Rate"
  ) +
  theme_nature_neuroscience() +
  theme(axis.text.x = element_blank())

# Beta (Inverse Temperature) plot
p_beta <- ggplot(filter(plot_data, parameter == "β (Inverse Temperature)"), 
                 aes(x = parameter_short, y = value)) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1.5, color = "darkgreen") +
  geom_boxplot(fill = "lightgreen", alpha = 0.7, outlier.shape = NA) +
  stat_summary(fun = median, geom = "point", shape = 23, size = 4, fill = "red") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  labs(
    title = "Inverse Temperature (β)",
    subtitle = paste("Median =", round(param_summary$median_val[2], 3), 
                    "| Mean =", round(param_summary$mean_val[2], 3)),
    x = NULL,
    y = "Inverse Temperature"
  ) +
  theme_nature_neuroscience() +
  theme(axis.text.x = element_blank())

# Omega (Precision Weight) plot
p_omega <- ggplot(filter(plot_data, parameter == "ω (Precision Weight)"), 
                  aes(x = parameter_short, y = value)) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1.5, color = "darkred") +
  geom_boxplot(fill = "lightcoral", alpha = 0.7, outlier.shape = NA) +
  stat_summary(fun = median, geom = "point", shape = 23, size = 4, fill = "red") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  labs(
    title = "Precision Weight (ω)",
    subtitle = paste("Median =", round(param_summary$median_val[3], 3), 
                    "| Mean =", round(param_summary$mean_val[3], 3)),
    x = NULL,
    y = "Precision Weight"
  ) +
  theme_nature_neuroscience() +
  theme(axis.text.x = element_blank())

# 6. CREATE STATISTICAL SUMMARY TABLE
# -----------------------------------------------------------------------------
cat("Creating statistical summary...\n")

# Perform statistical tests against zero
alpha_test <- t.test(successful_fits$alpha, mu = 0)
beta_test <- t.test(successful_fits$beta, mu = 0)
omega_test <- t.test(successful_fits$omega, mu = 0)

# Extract p-values and effect sizes
alpha_p <- alpha_test$p.value
beta_p <- beta_test$p.value
omega_p <- omega_test$p.value

alpha_t <- alpha_test$statistic
beta_t <- beta_test$statistic
omega_t <- omega_test$statistic

# Create summary table
summary_table <- data.frame(
  Parameter = c("α (Learning Rate)", "β (Inverse Temperature)", "ω (Precision Weight)"),
  N = rep(nrow(successful_fits), 3),
  Median = c(param_summary$median_val[1], param_summary$median_val[2], param_summary$median_val[3]),
  Mean = c(param_summary$mean_val[1], param_summary$mean_val[2], param_summary$mean_val[3]),
  SD = c(param_summary$sd_val[1], param_summary$sd_val[2], param_summary$sd_val[3]),
  t_statistic = c(alpha_t, beta_t, omega_t),
  p_value = c(alpha_p, beta_p, omega_p),
  significant = c(alpha_p < 0.001, beta_p < 0.001, omega_p < 0.001)
)

# 7. SAVE PLOTS AND RESULTS
# -----------------------------------------------------------------------------
cat("Saving plots and results...\n")

# Save main boxplot
ggsave("results/figures/rl_models/rl_parameters_boxplot.png", p1, 
       width = 10, height = 8, dpi = 300)

# Save individual parameter plots
ggsave("results/figures/rl_models/rl_alpha_boxplot.png", p_alpha, 
       width = 8, height = 6, dpi = 300)
ggsave("results/figures/rl_models/rl_beta_boxplot.png", p_beta, 
       width = 8, height = 6, dpi = 300)
ggsave("results/figures/rl_models/rl_omega_boxplot.png", p_omega, 
       width = 8, height = 6, dpi = 300)

# Save summary table
write.csv(summary_table, "results/tables/rl_parameter_summary.csv", row.names = FALSE)

cat("✓ Plots saved to results/figures/\n")
cat("✓ Summary table saved to results/tables/\n")

# 8. PRINT RESULTS SUMMARY
# -----------------------------------------------------------------------------
cat("\n=== RL Parameter Summary ===\n")
print(summary_table)

cat("\n=== Statistical Tests vs Zero ===\n")
cat("α (Learning Rate): t =", round(alpha_t, 3), ", p =", format.pval(alpha_p, digits = 3), "\n")
cat("β (Inverse Temperature): t =", round(beta_t, 3), ", p =", format.pval(beta_p, digits = 3), "\n")
cat("ω (Precision Weight): t =", round(omega_t, 3), ", p =", format.pval(omega_p, digits = 3), "\n")

cat("\n=== Interpretation ===\n")
cat("• α (Learning Rate):", ifelse(alpha_p < 0.001, "Significantly > 0", "Not significantly > 0"), "\n")
cat("• β (Inverse Temperature):", ifelse(beta_p < 0.001, "Significantly > 0", "Not significantly > 0"), "\n")
cat("• ω (Precision Weight):", ifelse(omega_p < 0.001, "Significantly > 0", "Not significantly > 0"), "\n")

cat("\n=== Key Findings ===\n")
cat("• Median learning rate:", round(param_summary$median_val[1], 3), "\n")
cat("• Median inverse temperature:", round(param_summary$median_val[2], 3), "\n")
cat("• Median precision weight:", round(param_summary$median_val[3], 3), "\n")
cat("• Participants show", ifelse(param_summary$median_val[3] > 0.5, "strong", "moderate"), "precision-weighting behavior\n")

cat("\n=== RL Parameter Visualization Complete ===\n") 