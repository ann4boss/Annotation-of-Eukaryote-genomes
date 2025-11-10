#!/bin/bash

#SBATCH --job-name=AGAT_Stats
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err


#==============================================================================
# SCRIPT: 14_run_agat.sh
# DESCRIPTION: Executes AGAT (Another GFF/GTF Analysis Tool) to generate a
#              comprehensive summary of the final, high-confidence gene annotation
#              set. This step produces key metrics like gene count, exon count,
#              average gene length, and other structural statistics.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Path to the AGAT Apptainer container
CONTAINER="/containers/apptainer/agat-1.2.0.sif"
# Input GFF3 file (from the quality filtering in Step 13)
MAKER_DIR="$WORKDIR/results/08_Maker"
FINAL_DIR="$MAKER_DIR/final"
GFF_INPUT="${FINAL_DIR}/filtered.genes.renamed.gff3"
# Dedicated output directory for AGAT results
OUTDIR="$WORKDIR/results/09_Agat_Stats"

# Define output file name
STATS_OUTPUT="annotation.stat"

#*-----Prerequisites and Directory Setup---------------------------------------*
# Create necessary output directory
mkdir -p "$OUTDIR"

# Change to the output directory
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"

#*-----Run AGAT for Annotation Statistics--------------------------------------*
echo "Starting AGAT statistics generation on $GFF_INPUT..."

# Execute AGAT inside the container
apptainer exec --bind ${WORKDIR} ${CONTAINER} agat_sp_statistics.pl \
    -i "$GFF_INPUT" \
    -o "$STATS_OUTPUT"

echo "AGAT job submitted. Statistics saved to: $STATS_OUTPUT"

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# annotation.stat (Text file containing detailed structural statistics of the GFF3)



