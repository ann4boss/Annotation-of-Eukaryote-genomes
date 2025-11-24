#!/bin/bash

#SBATCH --job-name=FastaCleanup
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=0-00:15:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 15_fasta_cleanup.sh
# DESCRIPTION: Synchronizes the final GFF3 gene list with the sequence FASTA
#              files (transcripts and proteins) using faSomeRecords.
#              This creates the final, ready-to-use FASTA files for annotation.
#==============================================================================

#*-----Variables and File Setup (Must match 13_quality_filter.sh)------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
FINAL_DIR="$WORKDIR/results/08_Maker/final"

# GFF file (containing the final list of genes)
GFF_FINAL_CLEAN="filtered.genes.renamed.gff3"

GENOME_NAME="hifiasm_assembly_Altai-5"
# Names for the input FASTA files (from MAKER renaming step)
TRANSCRIPT_INPUT_FASTA="${GENOME_NAME}.all.maker.transcripts.fasta.renamed.fasta"
PROTEIN_INPUT_FASTA="${GENOME_NAME}.all.maker.proteins.fasta.renamed.fasta"

# Define Output Files
LIST_FILE="final_gene_list.txt"
TRANSCRIPT_OUTPUT_FASTA="transcripts.final.fasta"
PROTEIN_OUTPUT_FASTA="proteins.final.fasta"

#*-----Setup and Execution-----------------------------------------------------*

# Navigate to the processing directory
cd "$FINAL_DIR" || exit

echo "--- Starting FASTA Sequence Synchronization ---"
echo "Working directory: $FINAL_DIR"

# 1. Load the required module
echo "1. Loading UCSC-Utils module..."
module load UCSC-Utils/448-foss-2021a
module load MariaDB/10.6.4-GCC-10.3.0

# 2. Extract the list of valid mRNA/transcript IDs from the final GFF3
echo "2. Extracting final gene model IDs from $GFF_FINAL_CLEAN..."
grep -P "\tmRNA\t" "$GFF_FINAL_CLEAN" | \
    awk '{print $9}' | \
    cut -d ';' -f1 | \
    sed 's/ID=//g' > "$LIST_FILE"

if [ $? -ne 0 ]; then echo "ERROR: ID extraction failed. Exiting."; exit 1; fi
echo "    -> Found $(wc -l < "$LIST_FILE") valid IDs."

# 3. Filter the Transcript FASTA file
echo "3. Filtering transcript FASTA ($TRANSCRIPT_INPUT_FASTA)..."
faSomeRecords "$TRANSCRIPT_INPUT_FASTA" "$LIST_FILE" "$TRANSCRIPT_OUTPUT_FASTA"
if [ $? -ne 0 ]; then echo "ERROR: Transcript filtering failed. Exiting."; exit 1; fi
echo "    -> Final transcripts saved to: $TRANSCRIPT_OUTPUT_FASTA"

# 4. Filter the Protein FASTA file
echo "4. Filtering protein FASTA ($PROTEIN_INPUT_FASTA)..."
faSomeRecords "$PROTEIN_INPUT_FASTA" "$LIST_FILE" "$PROTEIN_OUTPUT_FASTA"
if [ $? -ne 0 ]; then echo "ERROR: Protein filtering failed. Exiting."; exit 1; fi
echo "    -> Final proteins saved to: $PROTEIN_OUTPUT_FASTA"

echo ""
echo "--- FASTA Synchronization Complete. Sequences are now ready for annotation. ---"
# Check final counts
echo "Transcripts count: $(grep -c '^>' "$TRANSCRIPT_OUTPUT_FASTA")"
echo "Proteins count: $(grep -c '^>' "$PROTEIN_OUTPUT_FASTA")"