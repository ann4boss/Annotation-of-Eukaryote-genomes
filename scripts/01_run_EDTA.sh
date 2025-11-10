#!/bin/bash

#SBATCH --job-name=EDTA_Altai5
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=2-00:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 01_run_EDTA.sh
# DESCRIPTION: Runs the Extensive de novo TE Annotator (EDTA) pipeline
#              to generate a non-redundant Transposable Element (TE) library
#              and whole-genome TE annotations for the Altai-5 assembly.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/EDTA2.2.sif"

# Input Assembly File (full path)
INPUT_FASTA="${WORKDIR}/data/assemblies/hifiasm_assembly_Altai-5.fasta"

# Extract the base name of the genome file (EDTA uses this for all output files), e.g., hifiasm_assembly_Altai-5.fasta
GENOME_BASE=$(basename ${INPUT_FASTA})

# CDS file for gene masking (important for accurate TE annotation)
CDS_FILE="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_cds_20110103_representative_gene_model_updated"

# Dedicated output directory for this step
OUTDIR="${WORKDIR}/results/01_EDTA_annotation"


#*-----Prerequisites and Directory Setup---------------------------------------*
# Create necessary log and output directories
mkdir -p "${WORKDIR}/logs/output"
mkdir -p "${WORKDIR}/logs/error"
mkdir -p "$OUTDIR"

# Change to the output directory to ensure all EDTA files are written here
cd "$OUTDIR" || exit

echo "Starting EDTA annotation for ${GENOME_BASE}..."
echo "Output directory: $OUTDIR"

 
#*-----Run EDTA inside Apptainer Container-------------------------------------*
echo "Running EDTA..."
# --anno 1 ensures the whole-genome TE annotation GFF3 is created
apptainer exec --bind "/data/courses/assembly-annotation-course/CDS_annotation" --bind ${WORKDIR} ${CONTAINER} EDTA.pl \
    --genome ${INPUT_FASTA} \
    --species others \
    --step all \
    --sensitive 1 \
    --cds ${CDS_FILE} \
    --anno 1 \
    --threads ${SLURM_CPUS_PER_TASK}


echo "EDTA job submitted. Check logs for completion."


#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# - Non-redundant TE Library: ${GENOME_BASE}.mod.EDTA.TElib.fa
# - Whole-genome TE Annotation: ${GENOME_BASE}.mod.EDTA.TEanno.gff3
# - Intact TE Annotation: ${GENOME_BASE}.mod.EDTA.intact.gff3
# - Whole-genome TE Summary: ${GENOME_BASE}.mod.EDTA.TEanno.sum
# - RepeatMasker Output (for dating): ${GENOME_BASE}.mod.EDTA.anno/${GENOME_BASE}.mod.out