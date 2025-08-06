# Reports Directory

This directory contains programmatic reports for the CWT fMRI study analysis.

## GLMM Analysis Report

### Files

- **`glmms/glmm_report.qmd`** - Quarto source file for the GLMM analysis report
- **`glmms/glmm_report.html`** - Generated HTML report (professional, interactive)
- **`glmms/styles.css`** - Custom CSS styling for the report
- **`glmms/header.html`** - Additional HTML header elements
- **`glmms/render_report.sh`** - Script to regenerate the report
- **`glmms/create_glmm_report.R`** - Legacy R script (basic HTML output)

### Features

The Quarto report (`glmm_report.html`) includes:

- **Professional styling** with modern CSS
- **Interactive tables** with hover effects and sorting
- **Beautiful typography** and responsive design
- **Table of contents** with navigation
- **Model coefficient tables** with significance stars
- **Model fit statistics** comparison
- **Embedded figures** from existing analysis
- **Key findings summary** with tabbed sections
- **Complete model outputs** for reference
- **GitHub Pages ready** for web deployment

### How to Use

#### Quick Start
```bash
cd reports/glmms
./render_report.sh
```

#### Manual Rendering
```bash
cd reports/glmms
quarto render glmm_report.qmd --to html
```

#### View the Report
Open `glmm_report.html` in any web browser to view the report.

### Requirements

- **Quarto** (v1.4+): Install from https://quarto.org/
- **R packages**: `tidyverse`, `lme4`, `knitr`, `kableExtra`, `DT`, `plotly`

The `render_report.sh` script will check and install missing dependencies automatically.

### Report Structure

1. **Study Overview** - Experimental design and methodology
2. **Model Results** - Four GLMM models with detailed results
3. **Model Comparison** - Fit statistics and model comparison
4. **Key Findings** - Summary of main effects and interactions
5. **Complete Outputs** - Full model summaries for reference

### Advantages over Basic HTML

- **Professional appearance** with modern styling
- **Interactive elements** (hoverable tables, collapsible sections)
- **Better typography** and responsive design
- **GitHub Pages compatible** for web hosting
- **Version control friendly** (markdown source)
- **Extensible** (easy to add new sections or modify styling)

### Deployment

The report can be deployed to GitHub Pages by:
1. Pushing the files to a GitHub repository
2. Enabling GitHub Pages in repository settings
3. The HTML file will be automatically served

### Customization

- **Styling**: Edit `styles.css` for custom appearance
- **Content**: Modify `glmm_report.qmd` for new sections
- **Layout**: Adjust YAML header in `.qmd` file for different themes/options

---

*Generated on: August 6, 2024* 