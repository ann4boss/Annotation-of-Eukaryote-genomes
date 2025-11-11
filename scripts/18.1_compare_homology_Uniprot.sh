#!/bin/bash

#SBATCH --job-name=Uniprot_Annotation
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 18.1_functional_annotation_uniprot.sh
# DESCRIPTION: Performs BLASTP against the UniProt Viridiplantae reviewed
#              database and uses MAKER tools to integrate the best hit
#              functional information (Name, GO, Pfam) into the FASTA and GFF3.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Use longest proteins (from BUSCO prep) as the query
PROTEIN_QUERY="$WORKDIR/results/10_BUSCO/longest_proteins.fasta"
GFF_INPUT="$WORKDIR/results/08_Maker/final/filtered.genes.renamed.gff3"
COURSEDIR="/data/courses/assembly-annotation-course"
MAKERBIN="$COURSEDIR/CDS_annotation/softwares/Maker_v3.01.03/src/bin"

# Reference database path
UNIPROT_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/uniprot/uniprot_viridiplantae_reviewed.fa"
UNIPROT_FASTA="$UNIPROT_DB"
# Output directory
OUTDIR="$WORKDIR/results/11_Homology/Uniprot"
BLAST_OUTPUT="blastp_output_uniprot.m6"
BESTHITS_OUTPUT="blastp_output_uniprot.besthits"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading required modules (BLAST+)..."
module load BLAST+/2.15.0-gompi-2021a

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"

#*-----1. Run BLASTP against UniProt-------------------------------------------*
echo "Running blastp against UniProt Viridiplantae reviewed database..."

# Note: makeblastdb is assumed to be completed. Limiting to max_target_seqs 1 
# since we only need the best hit for the subsequent sorting step.
blastp -query "$PROTEIN_QUERY" -db "$UNIPROT_DB" \
    -num_threads 32 \
    -outfmt 6 \
    -evalue 1e-5 \
    -max_target_seqs 1 \
    -out "$BLAST_OUTPUT"

#*-----2. Isolate Best Hit per Query-------------------------------------------*
echo "Sorting BLAST output to isolate the single best hit per query..."
# Sort by query ID (k1), then by E-value (k12, smallest first, 'g' for numeric)
sort -k1,1 -k12,12g "$BLAST_OUTPUT" | sort -u -k1,1 --merge > "$BESTHITS_OUTPUT"


#*-----3. Functional Annotation (FASTA)----------------------------------------*
echo "Applying UniProt annotations to the FASTA file..."
cp "$PROTEIN_QUERY" "longest_proteins.fasta.original"

"$MAKERBIN/maker_functional_fasta" \
    "$UNIPROT_FASTA" \
    "$BESTHITS_OUTPUT" \
    "longest_proteins.fasta.original" \
    > "longest_proteins.annotated.uniprot.fasta"


#*-----4. Functional Annotation (GFF3)-----------------------------------------*
echo "Applying UniProt annotations to the GFF3 file..."
cp "$GFF_INPUT" "filtered.genes.renamed.gff3.original"

"$MAKERBIN/maker_functional_gff" \
    "$UNIPROT_FASTA" \
    "$BESTHITS_OUTPUT" \
    "filtered.genes.renamed.gff3.original" \
    > "filtered.genes.annotated.uniprot.gff3"

echo "UniProt annotation complete. Annotated files are in $OUTDIR."


