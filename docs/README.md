# Documentation

This directory contains GitHub-first documentation and reports for the CWT fMRI study.

## Reports

### GLMM Analysis Report

- **`glmm_analysis_report.md`** - Clean, readable markdown report (GitHub renders natively)
- **`glmm_analysis_report_embedded.md`** - Same report with embedded figures (self-contained)

### Features

✅ **GitHub-native rendering** - Markdown files render beautifully on GitHub  
✅ **Clean and readable** - Focus on key findings, not clutter  
✅ **Self-contained** - Embedded figures work when downloaded  
✅ **Easy to maintain** - Simple markdown syntax  
✅ **Collaborative** - Easy for others to read and contribute  

### How to Use

1. **View on GitHub**: Open `glmm_analysis_report_embedded.md` in your browser
2. **Download**: The embedded version works offline with all figures
3. **Edit**: Modify the markdown files to update the report

### Regenerating with Embedded Figures

```bash
cd docs
Rscript embed_figures.R
```

This will create `glmm_analysis_report_embedded.md` with all figures embedded as base64.

---

*This approach provides clean, readable reports that work perfectly on GitHub without complex dependencies.* 