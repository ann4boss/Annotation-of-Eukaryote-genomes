#!/bin/bash

#SBATCH --job-name=TE_Divergence_Binning
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 03_bin_te_divergence.sh
# DESCRIPTION: Processes the RepeatMasker output from EDTA to create a binned
#              data file (TE landscape/age profile) based on divergence.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Path to the RepeatMasker output file from EDTA Step 01
INPUT_FASTA="${WORKDIR}/results/01_EDTA_annotation/hifiasm_assembly_Altai-5.fasta.mod.EDTA.anno/hifiasm_assembly_Altai-5.fasta.mod.out"
# Dedicated output directory for this step
OUTDIR="${WORKDIR}/results/03_TE_Divergence_Binning"
# Path to the parsing script
PARSE_SCRIPT="${WORKDIR}/scripts/parseRM.pl"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading BioPerl module..."
module add BioPerl/1.7.8-GCCcore-10.3.0

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit

#*-----Run TE Divergence Binning-----------------------------------------------*
echo "Running parseRM.pl to generate TE divergence data..."
# parseRM.pl inputs:
# -i: RepeatMasker output file
# -l 50,1: Max divergence limit of 50%, with 1% bin increments
# -v: Verbose output (shows progress)
perl "$PARSE_SCRIPT" -i "$INPUT_FASTA" -l 50,1 -v

echo "TE divergence binning complete. Output file is in $OUTDIR"
# The main output file will be named "TE.RM.Rel.txt" or similar, 
# depending on the parseRM.pl version.

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# - TE.RM.Rel.txt or similar binned divergence data file.