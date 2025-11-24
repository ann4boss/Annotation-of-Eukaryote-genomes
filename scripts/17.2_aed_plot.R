#!/usr/bin/env Rscript

library(ggplot2)
library(tidyverse)

# ----- Command-line arguments -----
args <- commandArgs(trailingOnly = TRUE)
if(length(args) < 2){
  stop("Usage: Rscript 15.3_aed_plot.R <input_file> <output_dir>")
}
input_file <- args[1]
output_dir <- args[2]

# ----- Read AED values -----
aed_data <- read.table(input_file, header = TRUE)
colnames(aed_data) <- c("AED", "CDF")

# ----- Calculate percentage below threshold -----
aed_threshold <- 0.5
cdf_at_threshold <- aed_data$CDF[which.min(abs(aed_data$AED - aed_threshold))]
percentage_below_threshold <- round(cdf_at_threshold * 100, 1)

# ----- Generate plot -----
p <- ggplot(aed_data, aes(AED, CDF)) +
    geom_line(color = "#1B2A41", linewidth = 1.2) +
    geom_area(fill = "#1B2A41", alpha = 0.15) +
    geom_vline(xintercept = aed_threshold, linetype = "dotted", color = "#8B1E3F", linewidth = 1) +
    annotate(
        "text",
        x = aed_threshold + 0.03,
        y = 0.1,
        label = paste0(percentage_below_threshold, "% ≤ AED 0.5"),
        hjust = 0,
        size = 5,
        color = "#8B1E3F"
    ) +
    scale_x_continuous(expand = c(0, 0), limits = c(0, 1)) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(
        title = "Cumulative Distribution of Annotation Edit Distance (AED)",
        x = "AED",
        y = "Cumulative Fraction of Gene Models"
    ) +
    theme_minimal(base_size = 15) +
    theme(
        plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank()
    )

# ----- Save plot -----
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
plot_file <- file.path(output_dir, "AED_CDF_plot.png")
ggsave(plot_file, plot = p, width = 8, height = 6)
cat("Plot saved to:", plot_file, "\n")
