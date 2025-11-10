#!/bin/bash

#SBATCH --job-name=TEsorter_LTR_Altai5
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 02_run_TEsorter.sh
# DESCRIPTION: Classifies full-length LTR retrotransposons (LTR-RTs) generated
#              by EDTA using TEsorter and the rexdb-plant database.
#              This refines the classification from Superfamily (Copia/Gypsy)
#              down to the Clade level, which is necessary for the LTR identity
#              plot in the next step.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/TEsorter_1.3.0.sif" 
# Base name of the assembly file
GENOME_BASE="hifiasm_assembly_Altai-5.fasta"
# Input FASTA file: Full-length LTR-RT sequences from the EDTA raw output
INPUT_FASTA="${WORKDIR}/results/01_EDTA_annotation/${GENOME_BASE}.mod.EDTA.raw/${GENOME_BASE}.mod.LTR.raw.fa" 
# Dedicated output directory for this step
OUTDIR="${WORKDIR}/results/02_TEsorter_LTR_Clades"


#*-----Prerequisites and Directory Setup---------------------------------------*
# Create necessary output directories (log dirs created in 01_run_EDTA.sh)
mkdir -p "$OUTDIR"

# Change to the output directory
cd "$OUTDIR" || exit

echo "Starting TEsorter classification for LTR-RTs from ${GENOME_BASE}..."
echo "Input FASTA: $INPUT_FASTA"
echo "Output directory: $OUTDIR"

#*-----Run TEsorter inside Apptainer Container----------------------------------*
# TEsorter command: Use the raw LTR FASTA file and the rexdb-plant database
apptainer exec --bind ${WORKDIR} \
    ${CONTAINER} \
    TEsorter ${INPUT_FASTA} -db rexdb-plant

echo "TEsorter job submitted. Check logs for completion."

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# The output files are automatically named based on the input file's name:
# Input: ${GENOME_BASE}.mod.LTR.raw.fa
# Output 1 (Classification Table): ${GENOME_BASE}.mod.LTR.raw.fa.rexdb-plant.cls.tsv
# Output 2 (Annotated Proteins): ${GENOME_BASE}.mod.LTR.raw.fa.rexdb-plant.dom.faa