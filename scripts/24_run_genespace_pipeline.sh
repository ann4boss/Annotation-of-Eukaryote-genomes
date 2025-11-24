#!/bin/bash

#SBATCH --job-name=GENESPACE_Pipeline
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=1-00:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 24_run_genespace_pipeline.sh
# DESCRIPTION: Executes the three R scripts (GENESPACE run, Pangenome analysis,
#              and synteny visualization) inside the container.        
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
GENESPACE_WD="$WORKDIR/results/12_Genomespace"
COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
CONTAINER="$COURSEDIR/containers/genespace_latest.sif"
SCRIPT_DIR="$WORKDIR/scripts"

cd "$GENESPACE_WD" || exit

module load BioPerl/1.7.8-GCCcore-10.3.0
module load R/4.3.2-foss-2021a
module load R-bundle-CRAN/2023.11-foss-2021a
module load R-bundle-Bioconductor/3.18-foss-2021a-R-4.3.2


# Run initialization and GENESPACE
apptainer exec \
  --bind $COURSEDIR \
  --bind $WORKDIR \
  "$CONTAINER" Rscript $SCRIPT_DIR/21_run_genespace.R $GENESPACE_WD

# Run downstream analysis
Rscript "$SCRIPT_DIR/22_process_pangenome.R" "$GENESPACE_WD"

# Run visualization
apptainer exec \
  --bind $COURSEDIR \
  --bind $WORKDIR \
  "$CONTAINER" Rscript $SCRIPT_DIR/23_visualize_synteny.R $GENESPACE_WD



