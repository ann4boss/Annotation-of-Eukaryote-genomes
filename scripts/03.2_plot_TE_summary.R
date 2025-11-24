#!/usr/bin/env Rscript

#==============================================================================
# SCRIPT: 03.2_plot_TE_composition.R
# DESCRIPTION: Parse TE summary file and generate TE pie and donut
#              composition plots for interspersed repeats.
#==============================================================================

#*-----Command-line arguments--------------------------------------------------*
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: Rscript 03.2_plot_TE_composition.R <input_summary_file> <output_dir>")
}

INPUT_FILE <- args[1]
OUTDIR <- args[2]

#*-----Libraries---------------------------------------------------------------*
library(tidyverse)
library(data.table)
library(ggplot2)

#*-----Read input file---------------------------------------------------------*
text <- readLines(INPUT_FILE)

#*-----Extract genome size-----------------------------------------------------*
genome_line <- text[grepl("Total Length:", text)]
genome_size <- as.numeric(gsub("[^0-9]", "", sub(".*Total Length:", "", genome_line)))

#*-----Extract TE table--------------------------------------------------------*
# Lines between "Repeat Classes" and the blank line after its table
start <- grep("^Class", text)
end <- grep("^\\s*total interspersed", text)

block <- text[(start + 1):(end - 1)]

# Remove separators and blanks
block <- block[!grepl("^[-=]", block)]
block <- block[nchar(trimws(block)) > 0]

# Parse into Class and Family rows
df <- map_dfr(block, function(line) {

    # Class headings look like: "LINE -- -- --"
    if (grepl("^[A-Za-z_]+\\s+--", line)) {
        parts <- unlist(strsplit(trimws(line), "\\s+"))
        tibble(
            Class = parts[1],
            Family = NA,
            bpMasked = NA
        )
    } else {
        # Family lines start with spaces, example:
        # "    L1 659 500017 0.29%"
        parts <- unlist(strsplit(trimws(line), "\\s+"))
        fam <- parts[1]
        bp <- as.numeric(parts[3])

        tibble(
            Class = NA,
            Family = fam,
            bpMasked = bp
        )
    }
})

# Propagate Class labels downward
df <- df %>%
    fill(Class, .direction = "down") %>%
    filter(!is.na(Family)) %>%
    mutate(bpMasked = as.numeric(bpMasked))

#*-----Color definitions-------------------------------------------------------*
pie_colors <- c(
    "RestOfGenome" = "grey90",
    "LINE" = "#F8D961",
    "LTR" = "#EE4244",
    "SINE" = "#B6D944",
    "TIR" = "#132157",
    "nonLTR" = "#3C5541",
    "nonTIR" = "#e6ab02",
    "other" = "#638E6E"
)

family_colors <- c(
    "L1" = "#F8D961",
    "Copia" = "#F8A2A4",
    "Gypsy" = "#EE4244",
    "unknown" = "#B51F21",
    "tRNA" = "#B6D944",
    "CACTA" = "#132157",
    "Mutator" = "#3554A0",
    "PIF_Harbinger" = "#74a9cf",
    "Tc1_Mariner" = "#a6bddb",
    "hAT" = "#d0d1e6",
    "pararetrovirus" = "#3C5541",
    "helitron" = "#e6ab02",
    "repeat_fragment" = "#638E6E"
)

#*-----Pie chart---------------------------------------------------------------*
class_df <- df %>%
    group_by(Class) %>%
    summarise(bpMasked = sum(bpMasked)) %>%
    ungroup()

remaining <- genome_size - sum(class_df$bpMasked)

total_TE_percentage <- sum(class_df$bpMasked) / genome_size * 100

pie_df <- class_df %>%
    add_row(Class = "RestOfGenome", bpMasked = remaining) %>%
    mutate(percentage = bpMasked / sum(bpMasked) * 100)

pie_df$Class <- factor(
    pie_df$Class,
    levels = c("RestOfGenome", "LINE", "LTR", "SINE", "TIR", "nonLTR", "nonTIR", "other")
)

te_label <- paste0("Total TE: ", round(total_TE_percentage, 1), "%")

p1 <- ggplot(pie_df, aes(x = "", y = percentage, fill = Class)) +
    geom_col(color = "white") +
    coord_polar(theta = "y", start = pi / 3) +
    scale_fill_manual(values = pie_colors) +
    annotate("label", x = 1, y = 25, label = te_label,
             size = 4, fontface = "bold", fill = "white") +
    theme_void() +
    theme(legend.title = element_blank())

#*-----Donut chart-------------------------------------------------------------*
donut_df <- df %>%
    mutate(percentage = bpMasked / genome_size * 100) %>%
    mutate(
        label = case_when(
            percentage >= 5 ~ sprintf("%.1f%%", percentage),
            percentage >= 1 ~ sprintf("%.1f%%", percentage),
            percentage >= 0.1 ~ "<1%",
            TRUE ~ ""
        )
    )

p2 <- ggplot(donut_df, aes(x = 2, y = percentage, fill = Family)) +
    geom_col(color = "white", width = 1) +
    geom_text(aes(label = label),
              position = position_stack(vjust = 0.5),
              size = 3, fontface = "bold") +
    coord_polar(theta = "y") +
    scale_fill_manual(values = family_colors) +
    xlim(0.5, 2.5) +
    theme_void() +
    theme(legend.title = element_blank())

#*-----Save plots--------------------------------------------------------------*
pdf(file.path(OUTDIR, "TE_class_pie.pdf"), width = 6, height = 6)
print(p1)
dev.off()

pdf(file.path(OUTDIR, "TE_family_donut.pdf"), width = 6, height = 6)
print(p2)
dev.off()

ggsave(file.path(OUTDIR, "TE_class_pie.png"), p1, width = 6, height = 6, dpi = 300)
ggsave(file.path(OUTDIR, "TE_family_donut.png"), p2, width = 6, height = 6, dpi = 300)

cat("Plots written to:", OUTDIR, "\n")
