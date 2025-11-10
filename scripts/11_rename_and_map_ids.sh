#!/bin/bash
#SBATCH --job-name=RenameIDs
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=0-00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 11_rename_and_map_ids.sh
# DESCRIPTION: Creates a consistent and standardized ID map for all MAKER-derived
#              features (genes, transcripts, proteins). This replaces the long,
#              internal MAKER IDs with a clean, short prefix (e.g., ALT5000001)
#              and updates the GFF3 and FASTA files accordingly.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
# Path to the MAKER binaries
MAKERBIN="$COURSEDIR/softwares/Maker_v3.01.03/src/bin"
# Directory containing the merged MAKER outputs
MAKER_DIR="$WORKDIR/results/08_Maker"

GENOME_NAME="hifiasm_assembly_Altai-5"

# Define input file names
GFF="${GENOME_NAME}.all.maker.noseq.gff"
PROTEIN="${GENOME_NAME}.all.maker.proteins.fasta"
TRANSCRIPT="${GENOME_NAME}.all.maker.transcripts.fasta"

# Define the 3-4 letter prefix for your accession
PREFIX="ALT5"

#*-----Create Final Directory and Copy Files-----------------------------------*
FINAL_DIR="$MAKER_DIR/final"
echo "Setting up working directory: $FINAL_DIR"

# Create the final directory and navigate to the MAKER results directory
mkdir -p "$FINAL_DIR"
cd "$MAKER_DIR"

# Copy merged files to the final directory, giving them a base name for processing
cp $GFF $FINAL_DIR/${GFF}.renamed.gff
cp $PROTEIN $FINAL_DIR/${PROTEIN}.renamed.fasta
cp $TRANSCRIPT $FINAL_DIR/${TRANSCRIPT}.renamed.fasta

# Change into the processing directory
cd "$FINAL_DIR" || exit

#*-----ID Mapping and Renaming-------------------------------------------------*
echo "1. Creating ID map with prefix: $PREFIX..."

# 1. Create ID map (id.map) based on the GFF3 file
# --prefix $PREFIX: Sets the new ID prefix
# --justify 7: Pads the number to 7 digits (e.g., ALT5000001)
$MAKERBIN/maker_map_ids --prefix $PREFIX --justify 7 ${GFF}.renamed.gff > id.map

echo "2. Mapping new IDs in GFF3 file..."
# 2. Map IDs in the GFF3 file
$MAKERBIN/map_gff_ids "id.map" "${GFF}.renamed.gff"

echo "3. Mapping new IDs in FASTA files..."
# 3. Map IDs in the FASTA files
$MAKERBIN/map_fasta_ids "id.map" "${PROTEIN}.renamed.fasta"
$MAKERBIN/map_fasta_ids "id.map" "${TRANSCRIPT}.renamed.fasta"

echo "ID renaming complete. Files ready for InterProScan."

#*-----Expected Result Files in ${FINAL_DIR}--------------------------------------*
# id.map                                (The lookup table for old vs. new IDs)
# assembly.all.maker.noseq.gff.renamed.gff
# assembly.all.maker.proteins.fasta.renamed.fasta
# assembly.all.maker.transcripts.fasta.renamed.fasta