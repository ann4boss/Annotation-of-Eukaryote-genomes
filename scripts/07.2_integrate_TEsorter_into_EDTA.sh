#!/bin/bash

#SBATCH --job-name=Integrate_TEsorter
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=./logs/output/%x_%j.out
#SBATCH --error=./logs/error/%x_%j.err

#==============================================================================
# SCRIPT: 07.2_integrate_TEsorter_into_EDTA.sh
# DESCRIPTION: Integrates refined TE clade classifications from TEsorter
#              back into the EDTA-generated TE annotation GFF3 for Altai-5.
# AUTHOR: Anna Boss
# DATE: Nov 2025
#==============================================================================

#*-----Variables and File Setup------------------------------------------------*
WORKDIR="/data/users/aboss/annotation_of_eukaryote_genome"
GENOME_BASE="hifiasm_assembly_Altai-5.fasta"

# Original EDTA TE GFF3
GFF_IN="${WORKDIR}/results/01_EDTA_annotation/${GENOME_BASE}.mod.EDTA.TEanno.gff3"

# Refined TEsorter classification tables
COPIA_CLS="${WORKDIR}/results/06_TEsorter_Library_Clades/Copia_sequences.fa.rexdb-plant.cls.tsv"
GYPSY_CLS="${WORKDIR}/results/06_TEsorter_Library_Clades/Gypsy_sequences.fa.rexdb-plant.cls.tsv"

# Output integrated GFF3
GFF_OUT="${WORKDIR}/results/06_TEsorter_Library_Clades/${GENOME_BASE}.mod.EDTA.TEanno.integrated.gff3"

# Create output directory
mkdir -p "$(dirname "$GFF_OUT")"
cd "$(dirname "$GFF_OUT")" || exit

#*-----Load Modules------------------------------------------------------------*
module add SeqKit/2.6.1

#*-----Step 1: Combine TEsorter Classifications--------------------------------*
echo "Merging Copia and Gypsy classification tables..."
cat "$COPIA_CLS" "$GYPSY_CLS" > merged_cls.tsv

# Create a lookup file: TE_ID -> refined_clade
awk 'NR>1 {print $1"\t"$2}' merged_cls.tsv > cls_lookup.tsv

#*-----Step 2: Integrate into GFF3--------------------------------------------*
echo "Integrating refined classifications into GFF3..."

# Integrate refined clades into GFF3
awk 'BEGIN{
    FS=OFS="\t"
    # Load mapping table
    while((getline < "merged_cls.tsv") > 0){
        if($0 ~ /^#/ || NF < 4) continue
        split($1, a, "_INT")  # strip suffix
        base=a[1]
        clade= $4              # 4th column = Clade
        cls[base]=clade
    }
}
{
    if($1 ~ /^#/){ print; next }

    # Extract Name=
    name=""
    split($9, attr, ";")
    for(i in attr){
        if(attr[i] ~ /^Name=/){
            split(attr[i], kv, "=")
            name=kv[2]
        }
    }

    # If Name exists in class table, append new attribute
    if(name in cls){
        $9=$9";Refined_clade="cls[name]
    }

    print
}' "$GFF_IN" > "$GFF_OUT"


echo "Integration complete. Output saved to $GFF_OUT"

#*-----Expected Output--------------------------------------------------------*
# - GFF_OUT contains original TE annotations plus a new attribute "Refined_clade"
