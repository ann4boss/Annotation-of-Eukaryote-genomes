#!/bin/bash

#SBATCH --job-name=MergeMaker
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=0-00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 11_prep_maker_output.sh
# DESCRIPTION: Merges the fragmented GFF3, protein, and transcript files generated
#              by MAKER's parallel datastore into single, consolidated output
#              files. These merged files are required for the subsequent
#              post-processing steps like ID renaming and filtering.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
# Use the MAKER binaries from the course directory
MAKERBIN="$COURSEDIR/softwares/Maker_v3.01.03/src/bin"
# Directory containing the MAKER datastore and output control files
MAKER_DIR="$WORKDIR/results/08_Maker"
# Base name used by MAKER for its output directory
GENOME_NAME="hifiasm_assembly_Altai-5"

#*-----Merge GFF3 Files (Annotation Data)--------------------------------------*
# Navigate to the MAKER results directory
cd "$MAKER_DIR" || exit

echo "Starting GFF3 file merging from datastore log..."

# 1. Merge GFF3 with sequence data (usually needed only for visualization tools)
# -s: include sequence data
# -d: specify the datastore index log file
$MAKERBIN/gff3_merge -s -d ${GENOME_NAME}.maker.output/${GENOME_NAME}_master_datastore_index.log > ${GENOME_NAME}.all.maker.gff

# 2. Merge GFF3 WITHOUT sequence data (smaller, preferred for downstream processing)
# -n: do NOT include sequence data
# -s: (redundant but kept for consistency)
$MAKERBIN/gff3_merge -n -s -d ${GENOME_NAME}.maker.output/${GENOME_NAME}_master_datastore_index.log > ${GENOME_NAME}.all.maker.noseq.gff

echo "GFF3 merging complete."

#*-----Merge FASTA Files (Protein and Transcript Sequences)--------------------*
echo "Merging FASTA files (proteins and transcripts)..."

# The fasta_merge script automatically creates two files:
# assembly.all.maker.proteins.fasta and assembly.all.maker.transcripts.fasta
# -d: specify the datastore index log file
# -o: specify the prefix for the output FASTA files
$MAKERBIN/fasta_merge -d ${GENOME_NAME}.maker.output/${GENOME_NAME}_master_datastore_index.log -o ${GENOME_NAME}

echo "FASTA merging complete."

#*-----Expected Result Files in ${MAKER_DIR}-----------------------------------*
# assembly.all.maker.gff         (GFF3 file containing sequence)
# assembly.all.maker.noseq.gff   (GFF3 file without sequence)
# assembly.all.maker.proteins.fasta
# assembly.all.maker.transcripts.fasta