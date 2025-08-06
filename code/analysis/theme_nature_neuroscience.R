# Custom theme for Nature Neuroscience style plotting
# Based on Nature Neuroscience publication guidelines

library(ggplot2)

theme_nature_neuroscience <- function(base_size = 10, base_family = "sans") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Panel and background
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      
      # Text elements
      text = element_text(color = "black", size = base_size),
      axis.text = element_text(color = "black", size = base_size * 0.8),
      axis.title = element_text(color = "black", size = base_size, face = "bold"),
      plot.title = element_text(color = "black", size = base_size * 1.2, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(color = "black", size = base_size * 0.9, hjust = 0.5),
      legend.title = element_text(color = "black", size = base_size, face = "bold"),
      legend.text = element_text(color = "black", size = base_size * 0.8),
      
      # Axis lines
      axis.line = element_line(color = "black", linewidth = 0.5),
      axis.ticks = element_line(color = "black", linewidth = 0.5),
      axis.ticks.length = unit(0.2, "cm"),
      
      # Legend
      legend.background = element_rect(fill = "white", color = NA),
      legend.box.background = element_rect(fill = "white", color = NA),
      legend.key = element_rect(fill = "white", color = NA),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.box.just = "center",
      
      # Facets
      strip.background = element_rect(fill = "grey95", color = "black"),
      strip.text = element_text(color = "black", size = base_size * 0.8, face = "bold"),
      
      # Spacing
      plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
      panel.spacing = unit(0.3, "cm"),
      
      # Remove unnecessary elements
      panel.border = element_blank(),
      axis.title.y.right = element_blank(),
      axis.text.y.right = element_blank(),
      axis.ticks.y.right = element_blank()
    )
}

# Color palette for Nature Neuroscience style
nature_colors <- c(
  "Valid" = "#2E8B57",      # Sea green
  "Invalid" = "#CD5C5C",     # Indian red  
  "non-predictive" = "#4682B4", # Steel blue
  "low noise" = "#87CEEB",   # Sky blue
  "high noise" = "#4169E1",  # Royal blue
  "Angry" = "#DC143C",       # Crimson
  "Happy" = "#32CD32",       # Lime green
  "miss" = "#FF6347",        # Tomato
  "hit" = "#228B22"          # Forest green
)

# Alternative color palette (more muted)
nature_colors_muted <- c(
  "Valid" = "#4A6741",       # Dark olive green
  "Invalid" = "#8B4513",     # Saddle brown
  "non-predictive" = "#4682B4", # Steel blue
  "low noise" = "#87CEEB",   # Sky blue
  "high noise" = "#4169E1",  # Royal blue
  "Angry" = "#B22222",       # Fire brick
  "Happy" = "#228B22",       # Forest green
  "miss" = "#CD5C5C",        # Indian red
  "hit" = "#32CD32"          # Lime green
)

# Function to apply Nature Neuroscience style to existing plots
apply_nature_style <- function(plot_obj) {
  plot_obj + 
    theme_nature_neuroscience() +
    scale_fill_manual(values = nature_colors) +
    scale_color_manual(values = nature_colors)
}

# Print theme information
cat("Nature Neuroscience theme created successfully!\n")
cat("Use theme_nature_neuroscience() for new plots\n")
cat("Use apply_nature_style() for existing plots\n")
cat("Color palette available as 'nature_colors'\n") 