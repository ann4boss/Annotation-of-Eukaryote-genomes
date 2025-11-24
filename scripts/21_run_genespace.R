#!/usr/bin/env Rscript

#==============================================================================
# SCRIPT: 21_run_genespace.R
# DESCRIPTION: Initializes GENESPACE, runs OrthoFinder (DIAMOND2) and
#              synteny (MCScanX), and generates the pangenome matrix.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


library(GENESPACE)

args <- commandArgs(trailingOnly = TRUE)
wd <- args[1]

# Initialize GENESPACE
gpar <- init_genespace(
  wd = wd,
  path2mcscanx = "/usr/local/bin"
)

# Run GENESPACE pipeline
out <- run_genespace(gpar, overwrite = TRUE)

# Extract pangenome matrix
pangenome <- query_pangenes(
  out,
  bed = NULL,
  refGenome = "TAIR10",
  transform = TRUE,
  showArrayMem = TRUE,
  showNSOrtho = TRUE,
  maxMem2Show = Inf
)

# Save for downstream analysis
saveRDS(pangenome, file = file.path(wd, "pangenome_matrix.rds"))
