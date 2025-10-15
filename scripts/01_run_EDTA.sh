#!/bin/bash
#SBATCH --job-name=TE_annotation
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=2-00:00:00
#SBATCH --output=./logs/output/%x_%j.o
#SBATCH --error=./logs/error/%x_%j.e

# User-editable variables
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/EDTA2.2.sif"
INPUT_FASTA="${WORKDIR}/data/hifiasm_assembly_Altai-5.fasta"
OUTDIR="${WORKDIR}/results/EDTA_annotation"


#*-----Create Ouput directory-----
mkdir -p "$OUTDIR"
cd "$OUTDIR"


#*-----Run EDTA-----
echo "Running EDTA..."
apptainer exec --bind "/data/courses/assembly-annotation-course/CDS_annotation" --bind ${WORKDIR} ${CONTAINER} EDTA.pl \
    --genome ${INPUT_FASTA} \
    --species others \
    --step all \
    --sensitive 1 \
    --cds "/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_cds_20110103_representative_gene_model_updated" \
    --anno 1 \
    --threads ${SLURM_CPUS_PER_TASK}
