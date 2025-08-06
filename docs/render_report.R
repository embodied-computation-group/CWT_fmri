# Render GLMM Report
# This script renders the R Markdown report with embedded model statistics

library(rmarkdown)

cat("📊 Rendering GLMM Analysis Report...\n")

# Render the R Markdown report
render("glmm_report_simple.Rmd", 
       output_format = "html_document",
       output_file = "glmm_report.html",
       quiet = FALSE)

cat("✅ Report successfully generated: glmm_report.html\n")
cat("📁 The report includes:\n")
cat("   - Dynamic model statistics from pre-estimated models\n")
cat("   - Embedded figures from existing analysis\n")
cat("   - Reproducible content that updates with analysis changes\n")
cat("   - Professional HTML output with interactive tables\n") 