#!/bin/bash

#SBATCH --job-name=TAIR10_Annotation
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 19.2_functional_annotation_tair10.sh
# DESCRIPTION: Performs BLASTP against the Arabidopsis thaliana (TAIR10)
#              representative gene models to identify the best ortholog hit.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Use longest proteins (from BUSCO prep) as the query
PROTEIN_QUERY="$WORKDIR/results/10_BUSCO/longest_proteins.fasta"
COURSEDIR="/data/courses/assembly-annotation-course"

# Reference database path
TAIR10_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_pep_20110103_representative_gene_model"

# Output directory
OUTDIR="$WORKDIR/results/11_Homology/TAIR10"
BLAST_OUTPUT="blastp_output_TAIR10.m6"
BESTHITS_OUTPUT="blastp_output_TAIR10.besthits"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading required modules (BLAST+)..."
module load BLAST+/2.15.0-gompi-2021a

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"


#*-----1. Run BLASTP against TAIR10--------------------------------------------*
echo "Running blastp against TAIR10 representative proteins..."

# Note: makeblastdb is assumed to be completed. Limiting to max_target_seqs 1 
# since we only need the best hit for the subsequent sorting step.
blastp -query "$PROTEIN_QUERY" -db "$TAIR10_DB" \
    -num_threads 32 \
    -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle'\
    -evalue 1e-5 \
    -max_target_seqs 1 \
    -out "$BLAST_OUTPUT"

#*-----2. Isolate Best Hit per Query-------------------------------------------*
echo "Sorting BLAST output to isolate the single best hit per query..."
# Sort by query ID (k1), then by E-value (k12, smallest first, 'g' for numeric)
sort -k1,1 -k12,12g "$BLAST_OUTPUT" | sort -u -k1,1 --merge > "$BESTHITS_OUTPUT"

echo "TAIR10 BLAST complete. Best hits list saved to $BESTHITS_OUTPUT in $OUTDIR."


#*-----3. Compute Functional Annotation Summary--------------------------------*
echo "Calculating annotation statistics..."

DESCRIPTION_COLUMN=13
# Define your keywords for uncharacterized hits
UNCHAR_KEYWORDS="uncharacterized|hypothetical|unknown|putative|unnamed|predicted|unassigned"

# --- 1. Total number of query proteins (from the query FASTA file) ---
NUM_TOTAL=$(grep -c ">" "$PROTEIN_QUERY")

# --- 2. Single AWK pass to calculate non-overlapping counts ---
read -r NUM_WELL NUM_UNCHAR < <(awk -F'\t' '
{
    query = $1
    # Check the descriptive column (Col 2 is safer for .m6 files)
    subject = tolower($'${DESCRIPTION_COLUMN}') 
    
    # Flag 1: Did this query ever hit a well-annotated protein?
    # If the hit string does NOT contain any uncharacterized keyword
    if (subject !~ /'${UNCHAR_KEYWORDS}'/) {
        well_annotated[query] = 1
    }
    
    # Flag 2: Record every protein that had a hit
    all_hits[query] = 1
}
END {
    COUNT_WELL = 0
    COUNT_UNCHAR = 0
    
    # Iterate over all proteins that had at least one hit
    for (q in all_hits) {
        if (q in well_annotated) {
            # Counted as well-annotated if ANY hit was specific
            COUNT_WELL++
        } else {
            # Counted as uncharacterized if ALL of its hits were uncharacterized/hypothetical
            COUNT_UNCHAR++
        }
    }
    print COUNT_WELL, COUNT_UNCHAR
}' "$BESTHITS_OUTPUT")

# --- 3. Final Calculations ---
# The total number of proteins with ANY hit is the sum of the two non-overlapping sets
NUM_ANNOTATED=$(($NUM_WELL + $NUM_UNCHAR))

# Proportions are calculated based on the total number of genes in the genome
PROP_WELL=$(echo "scale=2; $NUM_WELL/$NUM_TOTAL*100" | bc)
PROP_UNCHAR=$(echo "scale=2; $NUM_UNCHAR/$NUM_TOTAL*100" | bc)

# --- Print Summary ---
echo ""
echo "===== UniProt Functional Annotation Summary (Corrected) ====="
echo "Total genome proteins (A): $NUM_TOTAL"
echo "Proteins with ANY UniProt hit (B): $NUM_ANNOTATED"
echo "---"
echo "  Functionally Annotated (Well-known): $NUM_WELL ($PROP_WELL % of A)"
echo "  Uncharacterized / Hypothetical Homologs: $NUM_UNCHAR ($PROP_UNCHAR % of A)"
echo "  No Homology Found (Novel/Error): $(($NUM_TOTAL - $NUM_ANNOTATED))"
echo "==========================================================="