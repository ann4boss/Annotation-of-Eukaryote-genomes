#!/bin/bash

#SBATCH --job-name=GENESPACE_Prep
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-01:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 20_prep_genespace_inputs.sh
# DESCRIPTION: Creates the structured directory required by the GENESPACE R
#              package, including the BED and peptide FASTA files for the
#              reference (TAIR10) and the selected accessions.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
ACCESSION="Altai5"
# Input files from your annotation
PROT_FASTA="$WORKDIR/results/10_BUSCO/longest_proteins.fasta"
GFF_INPUT="$WORKDIR/results/08_Maker/final/filtered.genes.renamed.gff3"
# Course data paths
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
LIAN_DATA="$COURSEDIR/data/Lian_et_al"

# GENESPACE working directory
GENESPACE_WD="$WORKDIR/results/12_Genomespace"
OUTDIR_BED="$GENESPACE_WD/bed"
OUTDIR_PEPTIDE="$GENESPACE_WD/peptide"

# External accessions to include
ACCESSION_2="Est0"
ACCESSION_3="Ice1"
ACCESSION_4="Etna2"

#*-----1. Create Directory Structure-------------------------------------------*
echo "Creating GENESPACE directory structure: $GENESPACE_WD"
mkdir -p "$OUTDIR_BED"
mkdir -p "$OUTDIR_PEPTIDE"

cd "$OUTDIR_BED" || exit

#*-----2. Prepare BED Files (chr, start-1, end, geneID)------------------------*
echo "Preparing BED files for all accessions in $OUTDIR_BED..."

# a) Your Accession (${ACCESSION}.bed)
echo "Processing GFF3 for $ACCESSION to create BED file..."
# create .bed file for my own accession + convert GFF3 (1-based start) to BED (0-based start)
grep -P "\tgene\t" $GFF_INPUT | awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' > ${ACCESSION}.bed

# create .bed file for other accessions
grep -P "\tgene\t" "$COURSEDIR/data/Lian_et_al/gene_gff/selected/Est-0.EVM.v3.5.ann.protein_coding_genes.gff" | awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' > ${ACCESSION_2}.bed
grep -P "\tgene\t" "$COURSEDIR/data/Lian_et_al/gene_gff/selected/Ice-1.EVM.v3.5.ann.protein_coding_genes.gff" | awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' > ${ACCESSION_3}.bed
grep -P "\tgene\t" "$COURSEDIR/data/Lian_et_al/gene_gff/selected/Etna-2.EVM.v3.5.ann.protein_coding_genes.gff" | awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' > ${ACCESSION_4}.bed
# copy bed file for TAIR10
cp "$COURSEDIR/data/TAIR10.bed" "$OUTDIR_BED/TAIR10.bed"

#*-----3. Prepare Peptide FASTA Files------------------------------------------*
echo "Preparing peptide FASTA files in $OUTDIR_PEPTIDE..."

cd "$OUTDIR_PEPTIDE" || exit

# a) Your Accession (${ACCESSION}.fa) - Uses longest proteins
echo "Copying $ACCESSION peptide FASTA..."
cp "$PROT_FASTA" "$OUTDIR_PEPTIDE/${ACCESSION}.fa"

# b) External Accession 2 (${ACCESSION_2}.fa)
echo "Copying $ACCESSION_2 peptide FASTA..."
PEPTIDE_2_FILE="$LIAN_DATA/protein/selected/Est-0.protein.faa"
cp "$PEPTIDE_2_FILE" "$OUTDIR_PEPTIDE/${ACCESSION_2}.fa"

# c) External Accession 3 (${ACCESSION_3}.fa)
echo "Copying $ACCESSION_3 peptide FASTA..."
PEPTIDE_3_FILE="$LIAN_DATA/protein/selected/Ice-1.protein.faa"
cp "$PEPTIDE_3_FILE" "$OUTDIR_PEPTIDE/${ACCESSION_3}.fa"

# c) External Accession 4 (${ACCESSION_4}.fa)
echo "Copying $ACCESSION_4 peptide FASTA..."
PEPTIDE_4_FILE="$LIAN_DATA/protein/selected/Etna-2.protein.faa"
cp "$PEPTIDE_4_FILE" "$OUTDIR_PEPTIDE/${ACCESSION_4}.fa"

# d) TAIR10 Reference (TAIR10.fa)
echo "Copying TAIR10 reference peptide FASTA..."
TAIR10_PEPTIDE="$COURSEDIR/data/TAIR10_pep_20110103_representative_gene_model"
cp "$TAIR10_PEPTIDE" "$OUTDIR_PEPTIDE/TAIR10.fa"


echo "GENESPACE preparation complete. Input files are in $GENESPACE_WD."



#*-----4. Clean FASTA headers to match BED IDs---------------------------------*
echo "Cleaning FASTA headers to match BED gene IDs..."
cd "$OUTDIR_PEPTIDE" || exit

# Clean headers for all FASTA files
for f in Altai5.fa TAIR10.fa; do
    sed -i 's/^>\([^ -]*\).*/>\1/' "$f"
done

echo "FASTA header cleaning complete. "









