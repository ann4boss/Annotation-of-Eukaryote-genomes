#!/usr/bin/env Rscript

library(circlize)
library(tidyverse)
library(ComplexHeatmap)

#==============================================================================
# SCRIPT: 06.2_circos_te_density.R
#==============================================================================

#*-----Argument Parsing--------------------------------------------------------*

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  stop("Usage: Rscript 05.2_circos_te_density.R <TE_GFF_PATH> <GENE_GFF_PATH> <FAI_PATH> <OUTPUT_DIR>")
}

TE_GFF_FILE <- args[1]
GENE_GFF_FILE <- args[2] 
FAI_FILE <- args[3]
PLOT_OUTDIR <- args[4]

if (!endsWith(PLOT_OUTDIR, "/")) {
    PLOT_OUTDIR <- paste0(PLOT_OUTDIR, "/")
}

#*-----Load and Filter Annotation Data-----------------------------------------*

# --- 1. Load FAI Data (Ideogram) ---
message("Reading FAI index file: ", FAI_FILE)
custom_ideogram <- read.table(FAI_FILE, header = FALSE, stringsAsFactors = FALSE, sep = "\t", fill = TRUE)

custom_ideogram$chr <- custom_ideogram$V1
custom_ideogram$start <- 1
custom_ideogram$end <- custom_ideogram$V2
custom_ideogram <- custom_ideogram[, c("chr", "start", "end")]
custom_ideogram <- custom_ideogram[order(custom_ideogram$end, decreasing = T), ]

# Select the top longest scaffolds
N_SCAFFOLDS <- 12
custom_ideogram <- custom_ideogram[1:N_SCAFFOLDS, ]
message(sprintf("Using top %d scaffolds (Total length: %.2f Mb)", 
                N_SCAFFOLDS, sum(custom_ideogram$end) / 1e6))


# --- 2. Load and Filter TE Annotation Data ---
message("Reading TE annotation GFF file: ", TE_GFF_FILE)
# Use read.table with skip=13 to bypass the known header block
te_gff_data <- read.table(
    TE_GFF_FILE, header = FALSE, sep = "\t", stringsAsFactors = FALSE, 
    skip = 13, comment.char = "", fill = TRUE
)
te_gff_data <- te_gff_data %>% 
  filter(nchar(V1) > 0 & nchar(V3) > 0 & nchar(V4) > 0 & V1 %in% custom_ideogram$chr)


# --- 3. Load and Filter Gene Annotation Data ---
gene_density_data <- NULL
is_gene_track_plotted <- FALSE
if (file.exists(GENE_GFF_FILE)) { 
  message("Reading Gene annotation file: ", GENE_GFF_FILE)
  gene_gff_data <- read.table(
      GENE_GFF_FILE, header = FALSE, sep = "\t", stringsAsFactors = FALSE, 
      comment.char = "", fill = TRUE
  )
  
  gene_density_data <- gene_gff_data %>%
    filter(!startsWith(V1, "#"), V1 %in% custom_ideogram$chr, V3 == "gene") %>%
    mutate(chrom = V1, start = V4, end = V5) %>%
    select(chrom, start, end)
    
    if (nrow(gene_density_data) > 0) {
        is_gene_track_plotted <- TRUE
    }
}


# --- Function to filter TE Superfamily ---
filter_superfamily <- function(gff_data, superfamily, custom_ideogram) {
    filtered_data <- gff_data[gff_data$V3 == superfamily, ] %>%
        as.data.frame() %>%
        mutate(chrom = V1, start = V4, end = V5) %>% 
        select(chrom, start, end) %>%
        filter(chrom %in% custom_ideogram$chr)
    return(filtered_data)
}

#*-----Circos Plot Generation Parameters---------------------------------------*

SF_NAMES <- c("Gypsy_LTR_retrotransposon", "Copia_LTR_retrotransposon", 
              "LTR_retrotransposon", "L1_LINE_retrotransposon","Mutator_TIR_transposon", "CACTA_TIR_transposon")
SF_COLORS <- c("#EE4244", "#F8A2A4", "#B51F21", "#F8D961", "#3554A0", "#132157")
GENE_COLOR <- "#d0d1e6" # Gene density color

TRACK_HEIGHT <- 0.10 
WINDOW_SIZE <- 1e5 

gaps <- c(rep(1, N_SCAFFOLDS - 1), 5) 

#*-----Function to Generate Plot-----------------------------------------------*

generate_circos_plot <- function() {
    # The plotting commands remain the same, wrapped in a function.
    circos.par(start.degree = 90, gap.after = 1, track.margin = c(0, 0), gap.degree = gaps)

    circos.genomicInitialize(
        custom_ideogram,
        plotType = c("axis", "labels")
    )

    # --- 1. Plot Gene Density (Innermost track) ---
    if (is_gene_track_plotted) {
      circos.genomicDensity(
        gene_density_data, 
        count_by = "number", 
        col = GENE_COLOR, 
        track.height = TRACK_HEIGHT, 
        window.size = WINDOW_SIZE
      )
    }

    # --- 2. Plot TE Superfamily Densities (Outer tracks) ---
    for (i in 1:length(SF_NAMES)) {
      sf <- SF_NAMES[i]
      col <- SF_COLORS[i]
      
      te_data <- filter_superfamily(te_gff_data, sf, custom_ideogram)
      
      if (nrow(te_data) == 0) {
          warning(paste("No data found for", sf, ". Skipping track."))
          next
      }

      circos.genomicDensity(
          te_data, 
          count_by = "number", 
          col = col, 
          track.height = TRACK_HEIGHT, 
          window.size = WINDOW_SIZE
      )
    }

    circos.clear()

    # Add Legend
    legend_items <- SF_NAMES
    legend_colors <- SF_COLORS

    if (is_gene_track_plotted) {
      legend_items <- c("Gene Density", legend_items)
      legend_colors <- c(GENE_COLOR, legend_colors)
    }

    lgd <- Legend(
        title = "Feature Density", 
        at = legend_items,
        legend_gp = gpar(fill = legend_colors),
        title_position = "topleft"
    )

    draw(lgd, x = unit(1, "npc") - unit(2, "mm"), y = unit(4, "mm"), 
        just = c("right", "bottom"))
}


#*-----Generate PDF Output-----------------------------------------------------*

PDF_OUT_FILE <- paste0(PLOT_OUTDIR, "05_TE_and_Gene_density_circos.pdf")
message("Generating PDF output: ", PDF_OUT_FILE)
pdf(PDF_OUT_FILE, width = 10, height = 10)
generate_circos_plot()
dev.off()


#*-----Generate PNG Output-----------------------------------------------------*

PNG_OUT_FILE <- paste0(PLOT_OUTDIR, "05_TE_and_Gene_density_circos.png")
message("Generating PNG output: ", PNG_OUT_FILE)
png(PNG_OUT_FILE, width = 10, height = 10, units = "in", res = 300, type = "cairo") 
generate_circos_plot()
dev.off()
message("Plot saved to ", PLOT_OUTDIR)