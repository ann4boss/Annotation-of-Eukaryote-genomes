#!/bin/bash

#SBATCH --job-name=Analyze_LTR_Clades_Altai5
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 06_wrapper_analyze_clades.sh
# DESCRIPTION: Prepares data and runs the R script (06.2_analyze_ltr_clades.R) to
#              analyze the clade-level classifications for Copia and Gypsy
#              elements derived from TEsorter (Step 5). It generates bar plots
#              and pie charts showing the abundance and proportion of key clades.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"

# Directory paths from previous steps
TESORTER_LIB_DIR="${WORKDIR}/results/05_TEsorter_Library_Clades"

# Dedicated output directory for this step (Step 6)
ANALYSIS_DIR="${WORKDIR}/results/06_Clade_Distribution_Analysis"

# Input files (outputs from Step 5)
COPIA_CLS_IN="${TESORTER_LIB_DIR}/Copia_sequences.fa.rexdb-plant.cls.tsv"
GYPSY_CLS_IN="${TESORTER_LIB_DIR}/Gypsy_sequences.fa.rexdb-plant.cls.tsv"


#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Setting up analysis directory at $ANALYSIS_DIR"

# Create necessary output directory
mkdir -p "$ANALYSIS_DIR"
cd "$ANALYSIS_DIR" || exit

# Copy required input classification files to the analysis directory
echo "Copying input classification tables from Step 5..."
cp "$COPIA_CLS_IN" .
cp "$GYPSY_CLS_IN" .

#*-----Load Modules and Run R Script-------------------------------------------*
echo "Loading required R module..."
module add BioPerl/1.7.8-GCCcore-10.3.0 
module add R/4.3.2-foss-2021a
module add R-bundle-CRAN/2023.11-foss-2021a
module add R-bundle-Bioconductor/3.18-foss-2021a-R-4.3.2


# R script should be saved in the WORKDIR/scripts directory
R_SCRIPT="${WORKDIR}/scripts/06.2_analyze_ltr_clades.R" 
echo "Executing R analysis script: $R_SCRIPT"

# Run the R script using Rscript (non-interactive mode)
Rscript "$R_SCRIPT" 

echo "R script finished. Plots and tables saved in $ANALYSIS_DIR"


#*-----Expected Result Files in ${ANALYSIS_DIR}--------------------------------*
# - Bar Plot (PNG): 06_LTR_clade_distribution_barplot.png
# - Pie Chart (PNG): 06_LTR_clade_proportions_piechart.png
# - Summary Counts Table (TSV): 06_LTR_clade_summary_counts.tsv
# - Proportions Table (TSV): 06_LTR_clade_proportions.tsv