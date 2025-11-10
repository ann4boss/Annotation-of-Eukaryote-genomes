#!/bin/bash

#SBATCH --job-name=QualityFilter
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=0-00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 13_quality_filter.sh
# DESCRIPTION:  This script executes post-MAKER annotation cleanup and quality filtering
#               using MAKER's utility scripts. It calculates the Annotation Edit Distance (AED)
#               distribution and filters gene models to retain only those with high confidence
#               (typically AED < 1) and/or those supported by functional domains (InterProScan/Pfam).
#               The final step filters the GFF3 file to contain only the primary gene features.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
# Path to the MAKER binaries
MAKERBIN="$COURSEDIR/softwares/Maker_v3.01.03/src/bin"
# Root MAKER results directory
MAKER_DIR="$WORKDIR/results/08_Maker"
# Directory containing renamed and IPR-annotated GFF files
FINAL_DIR="$MAKER_DIR/final"


# Base GFF name
GENOME_NAME="hifiasm_assembly_Altai-5"

# Define Input Files (from Step 11)
GFF_RENAMED="${GENOME_NAME}.all.maker.noseq.gff.renamed.gff"
GFF_IPRSCAN_INPUT="${GENOME_NAME}.all.maker.noseq.gff.renamed.iprscan.gff"

# Define Output Files
AED_OUTPUT="assembly.all.maker.renamed.gff.AED.txt"
GFF_FILTERED_TEMP="${GENOME_NAME}_iprscan_quality_filtered.gff"
GFF_FINAL_CLEAN="filtered.genes.renamed.gff3"


#*-----Run Annotation Filtering and Cleanup------------------------------------*
# Navigate to the processing directory
cd "$FINAL_DIR" || exit

echo "--- Starting Annotation Quality Filtering ---"
echo "Working directory: $FINAL_DIR"

# 1. Calculate Annotation Edit Distance (AED) distribution
echo "1. Calculating Annotation Edit Distance (AED) values..."
perl "$MAKERBIN/AED_cdf_generator.pl" -b 0.025 "$GFF_RENAMED" > "$AED_OUTPUT"
if [ $? -ne 0 ]; then echo "ERROR: AED calculation failed. Exiting."; exit 1; fi
echo "   -> AED distribution saved to: $AED_OUTPUT"

# 2. Apply comprehensive quality filter
echo "2. Applying quality filter (AED < 1 AND/OR Pfam domain)..."
# Filters GFF based on AED < 1.0 AND/OR the presence of a functional domain (Pfam/InterProScan).
perl "$MAKERBIN/quality_filter.pl" -s "$GFF_IPRSCAN_INPUT" > "$GFF_FILTERED_TEMP"
if [ $? -ne 0 ]; then echo "ERROR: Quality filtering failed. Exiting."; exit 1; fi
echo "   -> Quality-filtered GFF (temporary) saved to: $GFF_FILTERED_TEMP"

# 3. Filter GFF to keep only primary gene features
echo "3. Filtering GFF to keep only primary gene features..."
# We keep only 'gene', 'mRNA', 'CDS', 'exon', and UTR features.
grep -P "\t(gene|CDS|exon|five_prime_UTR|three_prime_UTR|mRNA)\t" \
    "$GFF_FILTERED_TEMP" > "$GFF_FINAL_CLEAN"
if [ $? -ne 0 ]; then echo "ERROR: Final GFF cleanup failed. Exiting."; exit 1; fi
echo "   -> Final clean GFF3 saved to: $GFF_FINAL_CLEAN"

# 4. Summary and Feature Count
echo ""
echo "--- Quality Filtering Complete ---"
echo "Check feature counts in $GFF_FINAL_CLEAN:"
# Count and list unique feature types remaining in the final GFF3 file
cut -f3 "$GFF_FINAL_CLEAN" | sort | uniq -c | sort -nr

#*-----Expected Result Files in ${FINAL_DIR}--------------------------------------*
# assembly.all.maker.renamed.gff.AED.txt (AED score distribution)
# assembly.all.maker.noseq.gff_iprscan_quality_filtered.gff (Temporary quality filtered GFF)
# filtered.genes.renamed.gff3 (Final set of high-confidence gene features)