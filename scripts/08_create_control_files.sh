#!/bin/bash
#SBATCH --job-name=ControlFiles_MAKER
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-00:30:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 08_create_control_files.sh
# DESCRIPTION: Initializes the MAKER gene annotation pipeline by generating the
#              default control files (maker_opts.ctl, maker_bopts.ctl, etc.)
#              These files must be manually configured before running MAKER.
# AUTHOR: Anna Boss
# DATE: Oct 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Path to the MAKER Apptainer container
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/MAKER_3.01.03.sif"
# Dedicated output directory for MAKER files
OUTDIR="${WORKDIR}/results/08_Maker"


#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Starting MAKER Control File Setup..."
echo "Output directory: $OUTDIR"

# Create the MAKER output directory
mkdir -p "$OUTDIR"

# Navigate to the output directory where control files will be placed
cd "$OUTDIR" || exit

#*-----Generate Control Files--------------------------------------------------*
echo "Generating MAKER control files..."

# Execute MAKER with the -CTL flag inside the container to generate the templates
apptainer exec --bind $WORKDIR ${CONTAINER} maker -CTL

echo "Control files created successfully in $OUTDIR."
echo "--- IMPORTANT: Please edit 'maker_opts.ctl' now before running the next step (08_run_MAKER.sh) ---"

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# maker_opts.ctl (Primary configuration file)
# maker_bopts.ctl
# maker_evm.ctl
# maker_exe.ctl