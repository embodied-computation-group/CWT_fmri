#!/bin/bash

# GLMM Report Renderer
# This script renders the Quarto report for the GLMM analysis

echo "📊 Rendering GLMM Analysis Report..."

# Check if Quarto is installed
if ! command -v quarto &> /dev/null; then
    echo "❌ Quarto is not installed. Please install Quarto first."
    echo "   Visit: https://quarto.org/docs/get-started/"
    exit 1
fi

# Check if required R packages are installed
echo "🔍 Checking R packages..."
Rscript -e "
packages <- c('tidyverse', 'lme4', 'knitr', 'kableExtra', 'DT', 'plotly')
missing <- packages[!packages %in% installed.packages()[,'Package']]
if (length(missing) > 0) {
  cat('Installing missing packages:', paste(missing, collapse=', '), '\n')
  install.packages(missing, repos='https://cran.rstudio.com/')
} else {
  cat('✅ All required packages are installed\n')
}
"

# Render the report
echo "📝 Rendering Quarto report..."
quarto render glmm_report.qmd --to html

if [ $? -eq 0 ]; then
    echo "✅ Report successfully generated: glmm_report.html"
    echo "📁 Files created:"
    ls -la *.html *.css *.qmd
else
    echo "❌ Error rendering report"
    exit 1
fi

echo ""
echo "🎉 Report generation complete!"
echo "📖 Open glmm_report.html in your browser to view the report"
echo "🌐 The report is ready for GitHub Pages deployment" 