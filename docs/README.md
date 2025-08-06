# Documentation

This directory contains reproducible reports for the CWT fMRI study.

## GLMM Analysis Report

### Files

- **`glmm_report_simple.Rmd`** - R Markdown source file (reproducible)
- **`glmm_report.html`** - Generated HTML report (self-contained, 2MB)
- **`render_report.R`** - Script to regenerate the report
- **`glmm_analysis_report.md`** - Static markdown version (GitHub-native)
- **`glmm_analysis_report_embedded.md`** - Static version with embedded figures

### Recommended Approach: R Markdown

**Use `glmm_report_simple.Rmd` for the best solution:**

✅ **Fully Reproducible** - Loads models and generates statistics dynamically  
✅ **Self-contained** - All figures embedded, works when downloaded  
✅ **Professional Output** - Beautiful HTML with interactive tables  
✅ **Easy to Update** - Just run `Rscript render_report.R` to regenerate  
✅ **No Manual Editing** - Everything is programmatic  

### How to Use

#### Regenerate the Report
```bash
cd docs
Rscript render_report.R
```

#### View the Report
Open `glmm_report.html` in any web browser.

### Features

- **Dynamic Model Statistics** - Extracts coefficients and significance from pre-estimated models
- **Interactive Tables** - Hover effects and professional styling
- **Embedded Figures** - All plots included, no broken links
- **Navigation** - Table of contents and section navigation
- **Professional Styling** - Clean, modern appearance

### Requirements

- **R** with packages: `tidyverse`, `lme4`, `knitr`, `kableExtra`, `rmarkdown`
- **Pandoc** (for HTML generation)

The `render_report.R` script will check dependencies and generate the report.

---

*This approach provides a truly reproducible, professional report that updates automatically with analysis changes.* 