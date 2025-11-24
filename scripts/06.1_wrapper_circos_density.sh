#!/bin/bash

#SBATCH --job-name=Circos_TE_Gene_Density
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:45:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 06.1_wrapper_circos_density.sh
# DESCRIPTION: Runs the R script to visualize cleaned genomic distribution 
#              and density of TEs and Genes.
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"

# 1. Genome assembly FASTA file (for indexing and FAI path)
INPUT_FASTA="${WORKDIR}/data/assemblies/hifiasm_assembly_Altai-5.fasta"

# 2. Whole-genome TE annotation GFF3 file (Input 1 for R script)
TE_GFF_FILE="${WORKDIR}/results/01_EDTA_annotation/hifiasm_assembly_Altai-5.fasta.mod.EDTA.TEanno.gff3"
# 3. Whole-genome Gene annotation GFF3 file (Input 2 for R script)
GENE_GFF_FILE="${WORKDIR}/results/08_Maker/final/filtered.genes.renamed.gff3" 

# 4. FAI Index file (Input 3 for R script)
FAIX_FILE="${INPUT_FASTA}.fai"

# 5. Output Directory (Argument 4 for R script)
PLOT_OUTDIR="${WORKDIR}/results/05_TE_Density_Circos"


#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Setting up output directory at $PLOT_OUTDIR"
mkdir -p "$PLOT_OUTDIR"

# 1. Load Samtools and Generate FASTA Index (.fai)
echo "Generating FASTA index (.fai) for ideogram data..."
module add SAMtools/1.13-GCC-10.3.0
samtools faidx "$INPUT_FASTA"

# Check if FAI file exists
if [ ! -f "$FAIX_FILE" ]; then
    echo "ERROR: FASTA index file ($FAIX_FILE) was not created." >&2
    exit 1
fi

#*-----Load Modules and Run R Script-------------------------------------------*
echo "Loading required R module..."
module add BioPerl/1.7.8-GCCcore-10.3.0 
module add R/4.3.2-foss-2021a
module add R-bundle-CRAN/2023.11-foss-2021a
module add R-bundle-Bioconductor/3.18-foss-2021a-R-4.3.2

R_SCRIPT="${WORKDIR}/scripts/05.2_circos_te_density.R" 
echo "Executing R plotting script: $R_SCRIPT"

# Run the R script, passing all four required files and the output directory
Rscript "$R_SCRIPT" \
    "$TE_GFF_FILE" \
    "$GENE_GFF_FILE" \
    "$FAIX_FILE" \
    "$PLOT_OUTDIR"

echo "R script finished. Results should be in $PLOT_OUTDIR."