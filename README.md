# Genome Annotation of Arabidopsis thaliana Accession Altai-5 – University of Fribourg


## 1. Introduction

This repository contains scripts from the practical component of the course **SBL.30004: Organization and Annotation of Eukaryote Genomes** at the University of Fribourg (2025). The project focused on the *Arabidopsis thaliana* accession **Altai-5**, whose genome assembly (generated in a previous course, 473637: Genome and Transcriptome Assembly, University of Bern) consists of 171,153,468 bp across 958 contigs, with an NG50 of 15,087,710 bp. Altai-5 originates from the Chinese Altai Mountain range (Longitude: 88.400000, Latitude: 47.760000).

The main goals were to:

* Perform comprehensive transposable element (TE) annotation.
* Generate functional gene annotations using MAKER.
* Assess annotation quality via BUSCO and homology comparisons.
* Explore structural and pangenomic analyses using GeneSpace.


## 2. Prerequisites

Ensure the following are available:

* Access to the IBU cluster.
* A Bash environment with SLURM job scheduler.
* Apptainer for containerized bioinformatics tools or modules


## 3. Scripts

### Data Processing and TE Annotation

| Script                                 | Description                                      |
| -------------------------------------- | ------------------------------------------------ |
| `01_run_EDTA.sh`                       | Annotates transposable elements using EDTA.      |
| `02_run_TEsorter.sh`                   | Classifies TEs into families and clades.         |
| `03.1_wrapper_plot_TE_summary.sh`      | Wrapper to summarize TE content for plotting.    |
| `03.2_plot_TE_summary.R`               | Generates plots of TE abundance and composition. |
| `04.1_bin_te_divergence.sh`            | Bins TE sequences by divergence.                 |
| `04.2_wrapper_plot_divergence.sh`      | Wrapper for plotting divergence distributions.   |
| `04.3_plot_divergence.R`               | Creates TE divergence histograms.                |
| `05.1_wrapper_LTRS_identity.sh`        | Computes LTR sequence identity.                  |
| `05.2_full_length_LTRs_identity.R`     | Plots full-length LTR identity distributions.    |
| `06.1_wrapper_circos_density.sh`       | Prepares TE density data for Circos.             |
| `06.2_circos_te_density.R`             | Generates Circos plots of TE density.            |
| `07.1_run_TEsorter_library.sh`         | Builds custom TE library.                        |
| `07.2_integrate_TEsorter_into_EDTA.sh` | Integrates library into EDTA workflow.           |
| `08.1_wrapper_analyze_clades.sh`       | Prepares clade analysis data.                    |
| `08.2_analyze_ltr_clades.R`            | Plots LTR clade distributions.                   |

### Gene Annotation and Functional Assessment

| Script                          | Description                                         |
| ------------------------------- | --------------------------------------------------- |
| `09_create_control_files.sh`    | Prepares configuration files for MAKER.             |
| `10_run_MAKER.sh`               | Executes MAKER genome annotation pipeline.          |
| `11_prep_maker_output.sh`       | Post-processing of MAKER GFF and FASTA outputs.     |
| `12_rename_and_map_ids.sh`      | Standardizes gene identifiers.                      |
| `13_interproscan_gff_update.sh` | Adds InterProScan functional annotations.           |
| `14_quality_filter.sh`          | Filters low-quality gene models.                    |
| `15_fasta_cleanup.sh`           | Cleans FASTA files for downstream analysis.         |
| `16_run_agat.sh`                | Runs AGAT scripts for annotation formatting and QC. |
| `17.1_wrapper_aed_plot.sh`      | Prepares Annotation Edit Distance (AED) plots.      |
| `17.2_aed_plot.R`               | Generates AED distribution plots.                   |
| `18.1_prep_busco_fasta.sh`      | Prepares input files for BUSCO assessment.          |
| `18.2_run_busco_assessment.sh`  | Runs BUSCO for completeness evaluation.             |

### Homology and Pangenome Analyses

| Script                             | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| `19.1_compare_homology_Uniprot.sh` | Compares predicted proteins to UniProt.                    |
| `19.2_compare_homology_TAIR10.sh`  | Compares predicted proteins to TAIR10.                     |
| `20_prep_genespace_inputs.sh`      | Prepares input data for GeneSpace pangenome analysis.      |
| `21_run_genespace.R`               | Performs GeneSpace pangenome analysis.                     |
| `22_process_pangenome.R`           | Processes outputs of GeneSpace for downstream plotting.    |
| `23_visualize_synteny.R`           | Visualizes gene synteny across genomes.                    |
| `24_run_genespace_pipeline.sh`     | Full wrapper to run GeneSpace pipeline from input to plot. |

### Auxiliary

| Script       | Description                                                       |
| ------------ | ----------------------------------------------------------------- |
| `parseRM.pl` | Perl script to parse RepeatMasker outputs for summary statistics. |



## 4. Reproducibility

* **Accession analyzed:** Altai-5
* **Reference assembly:** HiFiasm genome assembly (Bern course)
* **Analysis timeframe:** September – November 2025


## 5. Contact

For questions or issues regarding this repository:
**Anna Boss:** [anna.boss@students.unibe.ch](mailto:anna.boss@students.unibe.ch)