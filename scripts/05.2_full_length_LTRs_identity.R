library(tidyverse)
library(data.table)
library(cowplot)

#-------------------------------------------------
# Input files (edit paths if needed)
#-------------------------------------------------
gff_file <- "genomic.fna.mod.LTR.intact.raw.gff3"
cls_file <- "genomic.fna.mod.LTR.raw.fa.rexdb-plant.cls.tsv"
# cls_file is the output from TEsorter on the raw LTR-RT fasta file
#-------------------------------------------------
# Read and preprocess input data
#-------------------------------------------------
message("Reading GFF: ", gff_file)
anno <- read.table(gff_file, sep = "\t", header = FALSE)

# Remove subfeatures (Terminal repeats, TSDs) so we keep top-level TE annotations
exclude_feats <- c("long_terminal_repeat", "repeat_region", "target_site_duplication")
anno <- anno %>% filter(!V3 %in% exclude_feats)

# Extract Name and ltr_identity from the ninth column (attributes). This uses regex.
anno <- anno %>%
  rowwise() %>%
  mutate(
    # extract Name=... from attributes (V9)
    Name = str_extract(V9, "(?<=Name=)[^;]+"),
    # extract ltr_identity=... 
    Identity = as.numeric(str_extract(V9, "(?<=ltr_identity=)[^;]+")),
    # compute length as end - start
    length = as.numeric(V5) - as.numeric(V4)
  ) %>%
  # keep only the columns used downstream
  select(V1, V4, V5, V3, Name, Identity, length)

message("Reading classification: ", cls_file)
# Read classification table (TE name in first column). If your file doesn't have a header, set header=FALSE.
cls <- fread(cls_file, sep = "\t", header = TRUE)
setnames(cls, 1, "TE")

# TEsorter outputs encode the internal domain classification as TEName_INT#Classification. We split on '#',
# then keep only rows that correspond to internal-domain matches (Name ends with _INT), and strip _INT.
cls <- cls %>%
  separate(TE, into = c("Name", "Classification"), sep = "#", fill = "right") %>%
  filter(str_detect(Name, "_INT")) %>%
  mutate(Name = str_remove(Name, "_INT$"))

## Merge annotation with classification table
# Use a left join so all annotated TEs are kept even if they have no classification match
anno_cls <- merge(anno, cls, by = "Name", all.x = TRUE)

# Quick checks: how many per Superfamily/Clade (may be NA if classification missing)
message("Counts per Superfamily")
print(table(anno_cls$Superfamily, useNA = "ifany"))
message("Counts per Clade")
print(table(anno_cls$Clade, useNA = "ifany"))

# ----------------------------------------------------------------------
# NEW STEP: Calculate N and adjust Clade factors for plotting
# ----------------------------------------------------------------------
message("Adjusting clade labels with counts...")

# 1. Filter for the TEs that will be plotted (have both Identity and Clade)
anno_cls_plotready <- anno_cls %>%
    filter(Superfamily %in% c("Copia", "Gypsy"), !is.na(Identity), !is.na(Clade))

# 2. Calculate N (count) for each Clade
clade_counts <- anno_cls_plotready %>%
    group_by(Superfamily, Clade) %>%
    summarise(n = n(), .groups = 'drop') %>%
    mutate(Clade_Label = paste0(Clade, " (n=", n, ")")) %>%
    # Select only the Superfamily and new label to join back later
    select(Superfamily, Clade, Clade_Label)

# 3. Merge the new labels back into the main data frame
anno_cls <- left_join(anno_cls, clade_counts, by = c("Superfamily", "Clade"))

# 4. Update the Superfamily label to include the total count
# Calculate total N for Copia and Gypsy
sf_counts <- anno_cls_plotready %>%
    group_by(Superfamily) %>%
    summarise(total_n = n(), .groups = 'drop')

# Function to update title with (n=xx)
update_sf_label <- function(sf_name, counts_df) {
  n <- counts_df %>% filter(Superfamily == sf_name) %>% pull(total_n)
  if (length(n) > 0) {
    return(paste0(sf_name, " (n=", n, ")"))
  } else {
    return(sf_name)
  }
}

COPIA_TITLE <- update_sf_label("Copia", sf_counts)
GYPSY_TITLE <- update_sf_label("Gypsy", sf_counts)

message("Copia Plot Title: ", COPIA_TITLE)
message("Gypsy Plot Title: ", GYPSY_TITLE)
# ----------------------------------------------------------------------

#-------------------------------------------------
# Plot setup
#-------------------------------------------------
# binwidth controls histogram resolution around identity values 
binwidth <- 0.005
# x axis limits, these can be adjusted if needed, minimum identity in your data may differ
xlims <- c(0.80, 1.00)

# Compute a single y-max across ALL Copia and Gypsy clades. This ensures consistent y-axis scaling.
global_ymax <- anno_cls_plotready %>% # Use the plot-ready data frame
  # bin Identity into consistent breaks and count occurrences
  count(Superfamily, Clade, Identity = cut(Identity, seq(xlims[1], xlims[2], by = binwidth))) %>%
  pull(n) %>%
  max(na.rm = TRUE)

message("Global y-limit (shared for overview plots): ", global_ymax)

#-------------------------------------------------
# Plot function for one superfamily
#-------------------------------------------------
plot_by_clade <- function(df, sf, sf_title, ymax) {
  # 5. Use Clade_Label for faceting and define factor order
  plot_df <- df %>%
    filter(Superfamily == sf, !is.na(Clade_Label)) %>%
    # Ensure Clade_Label is a factor ordered alphabetically by the original Clade name
    mutate(Clade_Label = factor(Clade_Label, levels = sort(unique(Clade_Label[df$Superfamily == sf]))))
  
  ggplot(plot_df, aes(x = Identity)) +
    # histogram with color coding per superfamily
    geom_histogram(binwidth = binwidth,
                   color = "black",
                   fill = ifelse(sf == "Copia", "#F8A2A4", "#EE4244")) +
    # vertical stacking: one facet per Clade_Label (the one with n=xx)
    facet_wrap(~Clade_Label, ncol = 1, scales = "fixed") +
    # x axis focused around xlims values
    scale_x_continuous(limits = xlims, breaks = seq(xlims[1], xlims[2], 0.05)) +
    # set y limit to the provided ymax (useful for consistent overview plots)
    scale_y_continuous(limits = c(0, ymax), expand = c(0, 0)) +  
    theme_cowplot() +
    theme(strip.background = element_rect(fill = "#f0f0f0"),
          axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", hjust = 0.5)) +
    # Use the new sf_title for the main plot title
    labs(title = sf_title, x = "Identity", y = "Count")
}

#-------------------------------------------------
# Generate Copia and Gypsy plots
#-------------------------------------------------
# Pass the new titles to the function
p_copia <- plot_by_clade(anno_cls, "Copia", COPIA_TITLE, global_ymax)
p_gypsy <- plot_by_clade(anno_cls, "Gypsy", GYPSY_TITLE, global_ymax)

# Combine with cowplot side-by-side 
combined <- plot_grid(p_copia, p_gypsy, ncol = 2, rel_widths = c(1, 1))

ggsave("plots/04_LTR_Copia_Gypsy_cladelevel.png", combined, width = 12, height = 10, dpi = 300)
ggsave("plots/04_LTR_Copia_Gypsy_cladelevel.pdf", combined, width = 12, height = 10)