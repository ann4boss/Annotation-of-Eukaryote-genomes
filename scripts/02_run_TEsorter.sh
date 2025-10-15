#!/bin/bash

#SBATCH --job-name=TE_sorter
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=50G
#SBATCH --time=01:00:00
#SBATCH --output=./logs/output/%x_%j.o
#SBATCH --error=./logs/error/%x_%j.e

#*-----Variables---------
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
CONTAINER="/data/courses/assembly-annotation-course/containers2/TEsorter_1.3.0.sif"
INPUT_FASTA="${WORKDIR}/data/hifiasm_assembly_Altai-5.fasta"
assembly.fasta.mod.EDTA.raw/assembly.fasta.mod.LTR.raw.fa
OUTDIR="${WORKDIR}/results/TE_classification"



WORKDIR=/data/users/dbassi/assembly_and_annotation-course
THREADS=$SLURM_CPUS_PER_TASK
CONTAINER_DIR=/data/courses/assembly-annotation-course/containers2/TEsorter_1.3.0.sif
OUTPUT_DIR=$WORKDIR/EDTA_annotation/TE_sorter


mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

apptainer exec -C --bind ${WORKDIR} -H ${pwd}:/work \
    --writable-tmpfs -u ${CONTAINER} TEsorter ${INPUT_FASTA} -db rexdb-plant



