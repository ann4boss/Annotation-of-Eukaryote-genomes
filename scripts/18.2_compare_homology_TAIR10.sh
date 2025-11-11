#!/bin/bash

#SBATCH --job-name=TAIR10_Annotation
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 18.2_functional_annotation_tair10.sh
# DESCRIPTION: Performs BLASTP against the Arabidopsis thaliana (TAIR10)
#              representative gene models to identify the best ortholog hit.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Use longest proteins (from BUSCO prep) as the query
PROTEIN_QUERY="$WORKDIR/results/10_BUSCO/longest_proteins.fasta"
COURSEDIR="/data/courses/assembly-annotation-course"

# Reference database path
TAIR10_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_pep_20110103_representative_gene_model"

# Output directory
OUTDIR="$WORKDIR/results/11_Homology/TAIR10"
BLAST_OUTPUT="blastp_output_TAIR10.m6"
BESTHITS_OUTPUT="blastp_output_TAIR10.besthits"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading required modules (BLAST+)..."
module load BLAST+/2.15.0-gompi-2021a

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"


#*-----1. Run BLASTP against TAIR10--------------------------------------------*
echo "Running blastp against TAIR10 representative proteins..."

# Note: makeblastdb is assumed to be completed. Limiting to max_target_seqs 1 
# since we only need the best hit for the subsequent sorting step.
blastp -query "$PROTEIN_QUERY" -db "$TAIR10_DB" \
    -num_threads 32 \
    -outfmt 6 \
    -evalue 1e-5 \
    -max_target_seqs 1 \
    -out "$BLAST_OUTPUT"

#*-----2. Isolate Best Hit per Query-------------------------------------------*
echo "Sorting BLAST output to isolate the single best hit per query..."
# Sort by query ID (k1), then by E-value (k12, smallest first, 'g' for numeric)
sort -k1,1 -k12,12g "$BLAST_OUTPUT" | sort -u -k1,1 --merge > "$BESTHITS_OUTPUT"

echo "TAIR10 BLAST complete. Best hits list saved to $BESTHITS_OUTPUT in $OUTDIR."