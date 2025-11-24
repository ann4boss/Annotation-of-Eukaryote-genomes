#!/bin/bash

#SBATCH --job-name=TE_classification
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 07.1_run_TEsorter_library.sh
# DESCRIPTION: Refines the classification of the Copia and Gypsy retrotransposon
#              families from the EDTA-generated TE library. It extracts the
#              sequences using seqkit and classifies them into clades using
#              TEsorter with the rexdb-plant database.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"

# Corrected Container Path (matching the guide's explicit location)
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/TEsorter_1.3.0.sif"

# Base name of the assembly file
GENOME_BASE="hifiasm_assembly_Altai-5.fasta"

# Input FASTA file: Non-redundant TE Library from EDTA (Step 1)
INPUT_FASTA="${WORKDIR}/results/01_EDTA_annotation/${GENOME_BASE}.mod.EDTA.TElib.fa"

# Dedicated output directory for this step (Step 5)
OUTDIR="${WORKDIR}/results/06_TEsorter_Library_Clades"

# Sequence file names
COPIA_FA="Copia_sequences.fa"
GYPSY_FA="Gypsy_sequences.fa"

#*-----Prerequisites and Directory Setup---------------------------------------*
# Load SeqKit module for sequence extraction
echo "Loading SeqKit module..."
module add SeqKit/2.6.1

echo "Setting up output directory at $OUTDIR"
mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit

#*-----Step 1: Extract Copia and Gypsy Sequences-------------------------------*
echo "Extracting Copia and Gypsy sequences using seqkit..."

# Extract Copia sequences: -r (regex) -p (pattern)
seqkit grep -r -p "Copia" "$INPUT_FASTA" > "$COPIA_FA"
echo "Copia sequences extracted: $(grep -c '^>' "$COPIA_FA") elements"

# Extract Gypsy sequences
seqkit grep -r -p "Gypsy" "$INPUT_FASTA" > "$GYPSY_FA"
echo "Gypsy sequences extracted: $(grep -c '^>' "$GYPSY_FA") elements"


#*-----Step 2: Run TEsorter----------------------------------------------------*
echo "Running TEsorter on Copia library..."
# Apptainer exec command for Copia
apptainer exec --bind ${WORKDIR} \
    "${CONTAINER}" \
    TEsorter "$COPIA_FA" -db rexdb-plant

echo "Running TEsorter on Gypsy library..."
# Apptainer exec command for Gypsy
apptainer exec --bind ${WORKDIR} \
    "${CONTAINER}" \
    TEsorter "$GYPSY_FA" -db rexdb-plant

echo "TEsorter job submitted. Check logs for completion."


#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# - Copia Classification Table: Copia_sequences.fa.rexdb-plant.cls.tsv
# - Gypsy Classification Table: Gypsy_sequences.fa.rexdb-plant.cls.tsv
# - Copia Protein Sequences: Copia_sequences.fa.rexdb-plant.dom.faa
# - Gypsy Protein Sequences: Gypsy_sequences.fa.rexdb-plant.dom.faa