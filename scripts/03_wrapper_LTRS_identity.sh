#!/bin/bash

#SBATCH --job-name=LTR_Identity_Plot_Altai5
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 03_wrapper_LTRS_identity.sh
# DESCRIPTION: Prepares data and runs the R script to visualize the age
#              distribution of full-length Copia and Gypsy LTR retrotransposons
#              (LTR-RTs). Age is inferred from the percent identity between the
#              two flanking LTRs.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
GENOME_BASE="hifiasm_assembly_Altai-5.fasta"

# Directory paths from previous steps
EDTA_RAW_DIR="${WORKDIR}/results/01_EDTA_annotation/${GENOME_BASE}.mod.EDTA.raw"
TESORTER_DIR="${WORKDIR}/results/02_TEsorter_LTR_Clades"

# Dedicated output directory for this analysis (plots and temporary files)
ANALYSIS_DIR="${WORKDIR}/results/03_LTR_identity_analysis"

# Input files (from EDTA and TEsorter)
GFF_IN="${EDTA_RAW_DIR}/${GENOME_BASE}.mod.LTR.intact.raw.gff3"
CLS_IN="${TESORTER_DIR}/${GENOME_BASE}.mod.LTR.raw.fa.rexdb-plant.cls.tsv"

# The R plotting script provided by the course
R_SCRIPT="/data/courses/assembly-annotation-course/CDS_annotation/scripts/02-full_length_LTRs_identity.R"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Setting up analysis directory at $ANALYSIS_DIR"

# Create the main directory and the 'plots' subdirectory
mkdir -p "$ANALYSIS_DIR/plots"
cd "$ANALYSIS_DIR" || exit

# Placeholder names required by the R script's hardcoded input
GFF_RN="genomic.fna.mod.LTR.intact.raw.gff3"
CLS_RN="genomic.fna.mod.LTR.raw.fa.rexdb-plant.cls.tsv"

echo "Copying and renaming input files to match R script's expected names..."
cp "$GFF_IN" "$GFF_RN"
cp "$CLS_IN" "$CLS_RN"

#*-----Load Modules and Run R Script-------------------------------------------*
echo "Loading required software modules..."

# Load R and other necessary modules
# Note: BioPerl module is not strictly required for Rscript but is included if part of a larger pipeline dependency
module add BioPerl/1.7.8-GCCcore-10.3.0 
module add R/4.3.2-foss-2021a
module add R-bundle-CRAN/2023.11-foss-2021a


echo "Executing R plotting script: $R_SCRIPT"
# Run the R script using Rscript (non-interactive mode)
Rscript "$R_SCRIPT" 

echo "R script finished. Results saved."


#*-----Expected Result Files in ${ANALYSIS_DIR}/plots--------------------------*
# - LTR Identity Histogram (PNG): 01_LTR_Copia_Gypsy_cladelevel.png
# - LTR Identity Histogram (PDF): 01_LTR_Copia_Gypsy_cladelevel.pdf
