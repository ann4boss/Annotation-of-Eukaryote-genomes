#!/bin/bash

#SBATCH --job-name=TE_Summary_Plotting
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:20:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 03.1_wrapper_plot_TE_summary.sh
# DESCRIPTION: SLURM wrapper to execute the R script for plotting TE summary
#              including pie chart and family donut plot.
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# R script that produces both plots
R_SCRIPT="${WORKDIR}/scripts/03.2_plot_TE_summary.R"
# Input TE table 
INPUT_DATA="${WORKDIR}/results/01_EDTA_annotation/hifiasm_assembly_Altai-5.fasta.mod.EDTA.TEanno.sum"

# Genome size file or direct value
GENOME_SIZE=171153468

# Output directory
PLOT_OUTDIR="${WORKDIR}/results/01_EDTA_annotatio/Plots"
mkdir -p "$PLOT_OUTDIR"

#*-----Load Required Modules---------------------------------------------------*
echo "Loading R modules..."
module add R/4.3.2-foss-2021a
module add R-bundle-CRAN/2023.11-foss-2021a

#*-----Run R Plotting Script---------------------------------------------------*
echo "Running R script: $R_SCRIPT"

Rscript "$R_SCRIPT" \
    "$INPUT_DATA" \
    "$GENOME_SIZE" \
    "$PLOT_OUTDIR"

echo "Finished. Results in: $PLOT_OUTDIR"
