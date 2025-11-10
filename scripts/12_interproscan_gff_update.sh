#!/bin/bash

#SBATCH --job-name=InterPro
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=64
#SBATCH --mem=100G
#SBATCH --time=1-00:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 12_interproscan_gff_update.sh
# DESCRIPTION: Executes InterProScan on the newly renamed protein FASTA file to
#              find functional domains (e.g., Pfam, InterPro IDs). The resulting
#              annotations are then integrated back into the GFF3 file for
#              final quality assessment.
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
# Directory containing renamed GFF/FASTA files
FINAL_DIR="$MAKER_DIR/final"
# Path to the InterProScan Apptainer container
CONTAINER="$COURSEDIR/containers/interproscan_latest.sif"

GENOME_NAME="hifiasm_assembly_Altai-5"

# Define input file names
GFF_INPUT_RENAMED="${GENOME_NAME}.all.maker.noseq.gff.renamed.gff"
PROTEIN_INPUT_RENAMED="${GENOME_NAME}.all.maker.proteins.fasta.renamed.fasta"
# Define output names
IPR_OUTPUT="output.iprscan"
GFF_OUTPUT_IPR="${GENOME_NAME}.all.maker.noseq.gff.renamed.iprscan.gff"


#*-----Run InterProScan for Functional Annotation------------------------------*
# Navigate to the processing directory
cd "$FINAL_DIR" || exit

echo "Starting InterProScan on $PROTEIN_INPUT_RENAMED..."

# Execute InterProScan inside the container
apptainer exec \
    --bind $COURSEDIR/data/interproscan-5.70-102.0/data:/opt/interproscan/data \
    --bind $WORKDIR \
    --bind $COURSEDIR \
    --bind $SCRATCH:/temp \
    ${CONTAINER} \
    /opt/interproscan/interproscan.sh \
    -appl pfam --disable-precalc -f TSV \
    --goterms --iprlookup --seqtype p \
    -i $PROTEIN_INPUT_RENAMED -o $IPR_OUTPUT

echo "InterProScan finished. Output file: $IPR_OUTPUT"

#*-----Integrate IPR Results into GFF3-----------------------------------------*
echo "Updating GFF3 file ($GFF_INPUT_RENAMED) with functional annotations..."

# Use MAKER utility to merge IPR results into the GFF
$MAKERBIN/ipr_update_gff $GFF_INPUT_RENAMED $IPR_OUTPUT > $GFF_OUTPUT_IPR

echo "GFF file updated and saved as: $GFF_OUTPUT_IPR"

#*-----Expected Result Files in ${FINAL_DIR}--------------------------------------*
# output.iprscan                             (Raw InterProScan results in TSV format)
# assembly.all.maker.noseq.gff.renamed.iprscan.gff (GFF3 file with IPR functional annotations)
