# Embed Figures in Markdown Report
# Converts PNG figures to base64 and embeds them in the markdown

library(base64enc)

# Function to convert image to base64
image_to_base64 <- function(image_path) {
  if (file.exists(image_path)) {
    img_data <- readBin(image_path, "raw", file.info(image_path)$size)
    base64_data <- base64encode(img_data)
    return(paste0("data:image/png;base64,", base64_data))
  } else {
    warning(paste("Image file not found:", image_path))
    return(NULL)
  }
}

# List of figures to embed (corrected paths)
figures <- c(
  "accuracy" = "../results/figures/glmm_models/glmm_accuracy_model.png",
  "choice" = "../results/figures/glmm_models/glmm_choice_model.png", 
  "rt" = "../results/figures/glmm_models/glmm_rt_model.png",
  "confidence" = "../results/figures/glmm_models/glmm_confidence_model.png"
)

# Convert each figure to base64
cat("Converting figures to base64...\n")
base64_figures <- list()

for (name in names(figures)) {
  cat("Processing", name, "figure...\n")
  base64_data <- image_to_base64(figures[name])
  if (!is.null(base64_data)) {
    base64_figures[[name]] <- base64_data
    cat("✓", name, "converted successfully\n")
  }
}

# Create updated markdown content
markdown_content <- readLines("glmm_analysis_report.md")

# Replace image references with base64 data
for (name in names(base64_figures)) {
  # Find the line with the image reference
  pattern <- paste0("!\\[.*\\]\\(results/figures/glmm_models/glmm_", name, "_model\\.png\\)")
  
  for (i in seq_along(markdown_content)) {
    if (grepl(pattern, markdown_content[i])) {
      # Replace with base64 image
      new_line <- paste0("![", name, " Model Predictions](", base64_figures[[name]], ")")
      markdown_content[i] <- new_line
      cat("✓ Replaced", name, "figure reference\n")
    }
  }
}

# Write updated markdown file
writeLines(markdown_content, "glmm_analysis_report_embedded.md")

cat("\n✅ Successfully created glmm_analysis_report_embedded.md with embedded figures\n")
cat("📁 This file can be viewed directly on GitHub with all figures visible\n") 