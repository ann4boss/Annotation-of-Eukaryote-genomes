#!/bin/bash

#SBATCH --job-name=LongestIsoform
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 18.1_prep_busco_fasta.sh
# DESCRIPTION: Filters the high-confidence protein and transcript FASTA files
#              to retain only the longest isoform for each gene model. This is
#              the required input format for running a BUSCO quality assessment,
#              which assumes a single representative sequence per gene.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================


#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
# Dedicated output directory for BUSCO-ready files
OUTDIR="$WORKDIR/results/10_BUSCO"
# Input FASTA files
MAKER_DIR="$WORKDIR/results/08_Maker"
FINAL_DIR="$MAKER_DIR/final"

ORIG_PROT_FA="$FINAL_DIR/proteins.final.fasta"
ORIG_TRANS_FA="$FINAL_DIR/transcripts.final.fasta"

# Define output file names
PROT_LONGEST_LIST="protein_longest_isoform_ids.txt"
TRANS_LONGEST_LIST="transcript_longest_isoform_ids.txt"
PROT_FINAL_FASTA="longest_proteins.fasta"
TRANS_FINAL_FASTA="longest_transcripts.fasta"

#*-----Prerequisites and Directory Setup---------------------------------------*
echo "Loading required modules (SeqKit)..."
module load SAMtools/1.13-GCC-10.3.0
module load SeqKit/2.6.1

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit
echo "Working directory set to: $OUTDIR"

#*-----Generate Lengths and Select Longest Isoforms----------------------------*

echo "1. Generating sequence lengths and creating longest isoform list for proteins..."

# 1a. Generate length file (ID and Length)
seqkit fx2tab -l "$ORIG_PROT_FA" > protein_lengths.txt

# 1b. Use AWK to find the longest isoform ID for each gene (e.g., ALT5000001 from ALT5000001-RA)
awk '{
    # Extract the gene ID, assuming it is the part before the first hyphen (e.g., ALT5000001)
    match($1, /^([^-]+)/, gene_parts);
    gene_id = gene_parts[1];

    # Store the longest sequence ID seen so far for this gene
    if (!(gene_id in max_length) || $2 > max_length[gene_id]) {
        max_length[gene_id] = $2;
        longest_id[gene_id] = $1;
    }
}
END {
    # Output the full ID of the longest isoform
    for (gene in longest_id) {
        print longest_id[gene];
    }
}' protein_lengths.txt > "$PROT_LONGEST_LIST"

echo "2. Generating sequence lengths and creating longest isoform list for transcripts..."

# 2a. Generate length file
seqkit fx2tab -l "$ORIG_TRANS_FA" > transcript_lengths.txt

# 2b. Use AWK to find the longest isoform ID for each gene
awk '{
    # Extract the gene ID, assuming it is the part before the first hyphen
    match($1, /^([^-]+)/, gene_parts);
    gene_id = gene_parts[1];

    # Store the longest sequence ID seen so far for this gene
    if (!(gene_id in max_length) || $2 > max_length[gene_id]) {
        max_length[gene_id] = $2;
        longest_id[gene_id] = $1;
    }
}
END {
    # Output the full ID of the longest isoform
    for (gene in longest_id) {
        print longest_id[gene];
    }
}' transcript_lengths.txt > "$TRANS_LONGEST_LIST"


#*-----Final FASTA Extraction using SeqKit-------------------------------------*
echo "3. Filtering protein FASTA to keep only longest isoforms..."
seqkit grep -f "$PROT_LONGEST_LIST" "$ORIG_PROT_FA" -o "$PROT_FINAL_FASTA"

echo "4. Filtering transcript FASTA to keep only longest isoforms..."
seqkit grep -f "$TRANS_LONGEST_LIST" "$ORIG_TRANS_FA" -o "$TRANS_FINAL_FASTA"

echo "Longest isoform selection complete. Files ready for BUSCO assessment."

#*-----Expected Result Files in ${OUTDIR}--------------------------------------*
# protein_lengths.txt               (Raw length data for proteins)
# transcript_lengths.txt            (Raw length data for transcripts)
# protein_longest_isoform_ids.txt   (List of selected protein IDs)
# transcript_longest_isoform_ids.txt(List of selected transcript IDs)
# longest_proteins.fasta            (Final BUSCO input: Protein sequences)
# longest_transcripts.fasta         (Final BUSCO input: Transcript sequences)