#!/usr/bin/env Rscript

# Get command-line arguments (Input Data File and Output Plot Directory)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: Rscript plot_divergence.R <input_data_file> <output_plot_dir>", call. = FALSE)
}

#*-----File and Variable Setup-------------------------------------------------*
DATA_FILE <- args[1] # Path to the binned data file (e.g., TE.RM.Rel.txt)
PLOT_OUTDIR <- args[2] # Directory for the output PDF (e.g., .../Plots)
PLOT_FILENAME <- "TE_Divergence_Landscape.pdf"

#*-----Load Libraries----------------------------------------------------------*
library(reshape2)
library(tidyverse)
library(data.table)
library(RColorBrewer)
library(cowplot) # Used for theme_cowplot()


#*-----Define Custom Colors----------------------------------------------------*
# Define the family colors provided by the user
family_colors <- c(
    "LINE/L1" = "#F8D961",
    "LTR/Copia" = "#F29A9B",
    "LTR/Gypsy" = "#EE4244",
    "LTR/unknown" = "#B21E21",
    "SINE/tRNA" = "#B6D944",

    "DNA/DTA" = "#0A1D3F",
    "DNA/DTC" = "#26417A",
    "DNA/DTH" = "#4A70B8",
    "DNA/DTM" = "#7DA7D6",
    "DNA/DTT" = "#B2C7E9",
    
    "DNA/MULE-MuDR" = "#005663",
    "DNA/CMC-EnSpm" = "#002B33",
    
    "MITE/DTA" = "#3C5541",
    "MITE/DTC" = "#4A6A51",
    "MITE/DTH" = "#5A7F62",
    "MITE/DTM" = "#6C9675",
    "MITE/DTT" = "#7EAD89",

    "DNA/Helitron" = "#3C5541",
    "nonLTR/pararetrovirus" = "#e6ab02",

    "repeat_fragment" = "#638E6E"
)

# Filter the colors to only include those present in your dataset's levels
# We'll use this vector for scale_fill_manual

#*-----Data Loading and Processing---------------------------------------------*
rep_table <- fread(DATA_FILE, header = FALSE, sep = "\t")
print(head(rep_table))

# The parseRM.pl script output usually has the structure:
# Rname, Rclass, Rfam, bin1, bin2, ...
colnames(rep_table) <- c("Rname", "Rclass", "Rfam", 1:50)
rep_table <- rep_table %>% filter(Rfam != "unknown")
rep_table$fam <- paste(rep_table$Rclass, rep_table$Rfam, sep = "/")

rep_table.m <- melt(rep_table, id.vars = c("Rname", "Rclass", "Rfam", "fam"))

# Remove the peak at 1% divergence
rep_table.m <- rep_table.m %>% filter(variable != 1)

# Define the order of families for plotting
fam_levels <- c(
    "LTR/Copia", "LTR/Gypsy", 
    "DNA/DTA", "DNA/DTC", "DNA/DTH", "DNA/DTM", "DNA/DTT", "DNA/MULE-MuDR", "DNA/CMC-EnSpm",
    "MITE/DTA", "MITE/DTC", "MITE/DTH", "MITE/DTM", "MITE/DTT", 
    "LINE/L1", 
    "DNA/Helitron", "RC/Helitron"
)
rep_table.m$fam <- factor(rep_table.m$fam, levels = fam_levels)

rep_table.m$distance <- as.numeric(as.character(rep_table.m$variable)) / 100 # as it is percent divergence

# Remove helitrons as per note in original script
rep_table.m <- rep_table.m %>% filter(fam != "DNA/Helitron")
rep_table.m <- rep_table.m %>% filter(fam != "RC/Helitron")

# Calculate Age (Optional, but included for completeness)
# Substitution rate for the species
substitution_rate <- 8.22e-9 
rep_table.m$age <- rep_table.m$distance / (2 * substitution_rate)

#*-----Plotting----------------------------------------------------------------*
# Filter the custom colors to match only the levels present in the data after filtering
plot_colors <- family_colors[names(family_colors) %in% levels(rep_table.m$fam)]

divergence_plot <- ggplot(rep_table.m, aes(fill = fam, x = distance, weight = value / 1000000)) +
    geom_bar(width=0.01) + # Set width to 0.01 for 1% bins (0.01 distance)
    cowplot::theme_cowplot() +
    # Use the adjusted custom color scale
    scale_fill_manual(values = plot_colors, name = "TE Superfamily") +
    xlab("Divergence") +
    ylab("Sequence (Mbp)") +
    # Adjust X-axis to show 1% increments (0.01 distance)
    scale_x_continuous(breaks = seq(0, max(rep_table.m$distance), by = 0.05)) +
    theme(
        axis.text.x = element_text(angle = 90, vjust = 0.5, size = 9),
        plot.title = element_text(hjust = 0.5),
        legend.position = "right"
    )

# Save the plot
ggsave(
    filename = file.path(PLOT_OUTDIR, PLOT_FILENAME), 
    plot = divergence_plot,
    width = 10, 
    height = 5, 
    useDingbats = FALSE
)

ggsave(
    filename = file.path(PLOT_OUTDIR, sub("\\.pdf$", ".png", PLOT_FILENAME)), 
    plot = divergence_plot,
    width = 10, 
    height = 5, 
    dpi = 300 # Use a standard high resolution like 300 dpi
)

cat(paste("Plot saved to:", file.path(PLOT_OUTDIR, PLOT_FILENAME), "\n"))