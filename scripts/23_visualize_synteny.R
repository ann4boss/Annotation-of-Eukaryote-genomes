#!/usr/bin/env Rscript

library(GENESPACE)
args <- commandArgs(trailingOnly = TRUE)
wd <- args[1]

out <- wd #read_genespace(wd)

# Pairwise dotplots
plot_rawHits(out)
plot_syntenicHits(out)

# Riparian plot (multi-genome synteny)
plot_riparian(out, refGenome = "TAIR10", main = "Synteny map among accessions")
