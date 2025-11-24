#!/bin/bash
#SBATCH --job-name=AGAT_Stats
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=64
#SBATCH --mem=100G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 16_run_agat.sh
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
# Input GFF3 file (from the quality filtering
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


#*-----extract statistics of the file--------------------------------------*
STATIN="$OUTDIR/$STATS_OUTPUT"
SUMMARY_TABLE="$OUTDIR/filtered_annotation_summary.tsv"

echo "Extracting summary statistics from $STATIN"
echo -e "Metric\tValue" > "$SUMMARY_TABLE"

# Number of genes
GENES=$(grep -P "^Number of gene\s" "$STATIN" | awk '{print $4}')
echo -e "Number of genes\t$GENES" >> "$SUMMARY_TABLE"

# Number of mRNA
MRNA=$(grep -P "^Number of mrna\s" "$STATIN" | awk '{print $4}')
echo -e "Number of mRNA\t$MRNA" >> "$SUMMARY_TABLE"

# Genes with functional annotation
FUNC=$(grep -P "^Number of mrnas with at least one utr\s" "$STATIN" | awk '{print $7}')
echo -e "Genes with functional annotation\t$FUNC" >> "$SUMMARY_TABLE"

# Gene length stats
GENE_MIN=$(grep -P "^Shortest gene" "$STATIN" | awk '{print $4}')
GENE_MAX=$(grep -P "^Longest gene" "$STATIN" | awk '{print $4}')
GENE_MED=$(grep -P "^mean gene length" "$STATIN" | awk '{print $5}')
echo -e "Gene length median\t$GENE_MED" >> "$SUMMARY_TABLE"
echo -e "Gene length min\t$GENE_MIN" >> "$SUMMARY_TABLE"
echo -e "Gene length max\t$GENE_MAX" >> "$SUMMARY_TABLE"

# mRNA length stats
MRNA_MIN=$(grep -P "^Shortest mrna" "$STATIN" | awk '{print $4}')
MRNA_MAX=$(grep -P "^Longest mrna" "$STATIN" | awk '{print $4}')
MRNA_MED=$(grep -P "^mean mrna length" "$STATIN" | awk '{print $5}')
echo -e "mRNA length median\t$MRNA_MED" >> "$SUMMARY_TABLE"
echo -e "mRNA length min\t$MRNA_MIN" >> "$SUMMARY_TABLE"
echo -e "mRNA length max\t$MRNA_MAX" >> "$SUMMARY_TABLE"

# Exon length stats
EXON_MIN=$(grep -P "^Shortest exon" "$STATIN" | awk '{print $4}')
EXON_MAX=$(grep -P "^Longest exon" "$STATIN" | awk '{print $4}')
EXON_MED=$(grep -P "^mean exon length" "$STATIN" | awk '{print $5}')
echo -e "Exon length median\t$EXON_MED" >> "$SUMMARY_TABLE"
echo -e "Exon length min\t$EXON_MIN" >> "$SUMMARY_TABLE"
echo -e "Exon length max\t$EXON_MAX" >> "$SUMMARY_TABLE"

# Intron length stats (use intron into exon part)
INTRON_MIN=$(grep -P "^Shortest intron into exon part" "$STATIN" | awk '{print $6}')
INTRON_MAX=$(grep -P "^Longest intron into exon part" "$STATIN" | awk '{print $6}')
INTRON_MED=$(grep -P "^mean intron in exon length" "$STATIN" | awk '{print $6}')
echo -e "Intron length median\t$INTRON_MED" >> "$SUMMARY_TABLE"
echo -e "Intron length min\t$INTRON_MIN" >> "$SUMMARY_TABLE"
echo -e "Intron length max\t$INTRON_MAX" >> "$SUMMARY_TABLE"

# Monoexonic genes
MONO=$(grep -P "^Number of single exon gene\s" "$STATIN" | awk '{print $6}')
echo -e "Monoexonic genes\t$MONO" >> "$SUMMARY_TABLE"

# Exons per gene (use mean as AGAT reports no median)
EXON_PER_GENE_MIN=1
EXON_PER_GENE_MAX=$(grep -P "^Longest exon" "$STATIN" | awk '{print $4}')
EXON_PER_GENE_MED=$(grep -P "^mean exons per mrna" "$STATIN" | awk '{print $5}')
echo -e "Exons per gene median\t$EXON_PER_GENE_MED" >> "$SUMMARY_TABLE"
echo -e "Exons per gene min\t$EXON_PER_GENE_MIN" >> "$SUMMARY_TABLE"
echo -e "Exons per gene max\t$EXON_PER_GENE_MAX" >> "$SUMMARY_TABLE"

echo "Summary table written to $SUMMARY_TABLE"

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# annotation.stat (Text file containing detailed structural statistics of the GFF3)