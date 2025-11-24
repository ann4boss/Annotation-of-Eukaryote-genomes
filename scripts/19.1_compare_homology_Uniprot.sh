#!/bin/bash

#SBATCH --job-name=Uniprot_Annotation
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=64
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 19.1_functional_annotation_uniprot.sh
# DESCRIPTION: Performs BLASTP against the UniProt Viridiplantae reviewed
#              database and uses MAKER tools to integrate the best hit
#              functional information (Name, GO, Pfam) into the FASTA and GFF3.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Use longest proteins (from BUSCO prep) as the query
PROTEIN_QUERY="$WORKDIR/results/10_BUSCO/longest_proteins.fasta"
GFF_INPUT="$WORKDIR/results/08_Maker/final/filtered.genes.renamed.gff3"
COURSEDIR="/data/courses/assembly-annotation-course"
MAKERBIN="$COURSEDIR/CDS_annotation/softwares/Maker_v3.01.03/src/bin"

# Reference database path
UNIPROT_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/uniprot/uniprot_viridiplantae_reviewed.fa"
UNIPROT_FASTA="$UNIPROT_DB"
# Output directory
OUTDIR="$WORKDIR/results/11_Homology/Uniprot"
BLAST_OUTPUT="blastp_output_uniprot.m6"
BESTHITS_OUTPUT="blastp_output_uniprot.besthits"
BIAS_OUTPUT="protein_status_lengths.tsv"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading required modules (BLAST+)..."
module load BLAST+/2.15.0-gompi-2021a

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"

#*-----1. Run BLASTP against UniProt-------------------------------------------*
echo "Running blastp against UniProt Viridiplantae reviewed database..."

# Note: makeblastdb is assumed to be completed. Limiting to max_target_seqs 1 
# since we only need the best hit for the subsequent sorting step.
blastp -query "$PROTEIN_QUERY" -db "$UNIPROT_DB" \
    -num_threads 32 \
    -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle' \
    -evalue 1e-5 \
    -max_target_seqs 1 \
    -out "$BLAST_OUTPUT"

#*-----2. Isolate Best Hit per Query-------------------------------------------*
echo "Sorting BLAST output to isolate the single best hit per query..."
# Sort by query ID (k1), then by E-value (k12, smallest first, 'g' for numeric)
sort -k1,1 -k12,12g "$BLAST_OUTPUT" | sort -u -k1,1 --merge > "$BESTHITS_OUTPUT"


#*-----3. Functional Annotation (FASTA)----------------------------------------*
echo "Applying UniProt annotations to the FASTA file..."
cp "$PROTEIN_QUERY" "longest_proteins.fasta.original"

"$MAKERBIN/maker_functional_fasta" \
    "$UNIPROT_FASTA" \
    "$BESTHITS_OUTPUT" \
    "longest_proteins.fasta.original" \
    > "longest_proteins.annotated.uniprot.fasta"


#*-----4. Functional Annotation (GFF3)-----------------------------------------*
echo "Applying UniProt annotations to the GFF3 file..."
cp "$GFF_INPUT" "filtered.genes.renamed.gff3.original"

"$MAKERBIN/maker_functional_gff" \
    "$UNIPROT_FASTA" \
    "$BESTHITS_OUTPUT" \
    "filtered.genes.renamed.gff3.original" \
    > "filtered.genes.annotated.uniprot.gff3"

echo "UniProt annotation complete. Annotated files are in $OUTDIR."

#*-----5. Compute Functional Annotation Summary--------------------------------*
echo "Calculating UniProt functional annotation summary..."

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

#*-----5. Protein Length Bias Analysis (Pure Shell)----------------------------*
echo "Extracting protein lengths and hit status for R analysis..."

# A. Extract the list of UNIQUE proteins that have ANY hit (cleanly).
cut -f1 "$BESTHITS_OUTPUT" | \
awk '{
  # Ensure the Query ID is cleaned of any trailing whitespace
  gsub(/[ \r\t]+$/, "", $1);
  print $1
}' | sort -u > proteins_with_hits.list

# B. Extract ALL protein IDs and their lengths from the FASTA file.
# Using a single-line AWK script to avoid line break parsing errors.
awk 'BEGIN {OFS="\t"} /^>/ {if (id) print id, length(seq); id=substr($0, 2); sub(/ .*/, "", id); seq=""; next} {seq=seq$0} END {print id, length(seq)}' "$PROTEIN_QUERY" > protein_lengths.tmp

# C. Merge the two files using awk and assign 'Hit'/'NoHit' status.
# Reads hits.list first (FNR==NR) and then processes protein_lengths.tmp.
awk '
  BEGIN {FS="\t"; OFS="\t"} 
  FNR==NR {
    # Store all hit IDs from the first file (proteins_with_hits.list)
    hits[$1]=1; 
    next
  } 
  {
    # protein_lengths.tmp is now tab-separated: $1=ID, $2=Length
    id=$1; 
    prot_len=$2;
    
    # Check if the protein ID is in the hits array
    status="NoHit"; 
    if (id in hits) {
      status="Hit";
    } 
    
    # Print the final output columns: ID | Status | Length
    print id, status, prot_len
  }' proteins_with_hits.list protein_lengths.tmp > "$BIAS_OUTPUT"

# D. Clean up temporary files
echo "Cleaning up temporary files..."
rm proteins_with_hits.list protein_lengths.tmp

echo "Data extraction complete. Output file for R is: $OUTDIR/$BIAS_OUTPUT"
echo "Columns: GeneID | Status (Hit/NoHit) | Length (aa)"
echo "------------------------------------------------------------------------"