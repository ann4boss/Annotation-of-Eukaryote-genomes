#!/bin/bash

#SBATCH --job-name=Maker
#SBATCH --partition=pibu_el8
#SBATCH --mem=200G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=50
#SBATCH --time=7-00:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 10_run_MAKER.sh
# DESCRIPTION: Executes the MAKER gene annotation pipeline using MPI for parallel
#              processing. It uses the configured control files from step 07,
#              binding necessary software paths (AUGUSTUS, RepeatMasker) and
#              the temporary scratch space for the intensive computation.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
# Course data directory, required for binding external data (like protein evidence)
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
# Base project directory
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Path to the MAKER Apptainer container
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/MAKER_3.01.03.sif"
# Directory containing MAKER control files and where output will be stored
OUTPUT_DIR="$WORKDIR/results/08_Maker"
# Path to the RepeatMasker installation directory (needed for execution)
REPEATMASKER_DIR="/data/courses/assembly-annotation-course/CDS_annotation/softwares/RepeatMasker"


#*-----Load Modules----------------------------------------------------------*
echo "Loading required modules (OpenMPI for parallelism, AUGUSTUS for ab-initio prediction)..."

# Load MPI for mpiexec command
module load OpenMPI/4.1.1-GCC-10.3.0
# Load AUGUSTUS module which sets $AUGUSTUS_CONFIG_PATH (essential binding path)
module load AUGUSTUS/3.4.0-foss-2021a

export PATH=$PATH:"/data/courses/assembly-annotation-course/CDS_annotation/softwares/RepeatMasker"

#*-----Run MAKER with MPI--------------------------------------------------*
# Navigate to the directory containing the control files
cd "$OUTPUT_DIR" || exit

echo "Starting MAKER run with MPI on 50 tasks across 1 node..."

# mpiexec command runs MAKER inside the Apptainer container, binding all required paths
mpiexec --oversubscribe -n 50 apptainer exec \
    --bind $SCRATCH:/TMP \
    --bind $COURSEDIR \
    --bind $WORKDIR \
    --bind $AUGUSTUS_CONFIG_PATH \
    --bind $REPEATMASKER_DIR ${CONTAINER} \
    maker -mpi --ignore_nfs_tmp -TMP /TMP \
    maker_opts.ctl \
    maker_bopts.ctl \
    maker_evm.ctl \
    maker_exe.ctl

echo "MAKER execution finished. Check the $OUTPUT_DIR directory for output."

#*-----Expected Result Files in ${OUTPUT_DIR}--------------------------------------*
# ${GENOME_BASE}.maker.output/ (${GENOME_BASE} is replaced with the genome name)
# ${GENOME_BASE}.maker.gff (Intermediate GFF3 file containing raw annotations)
# Other log and temporary files.