library(ggplot2)
library(dplyr)
library(readr)
library(tidyr)

#==============================================================================
# SCRIPT: 06_analyze_ltr_clades.R
# DESCRIPTION: Reads TEsorter classification tables for Copia and Gypsy,
#              summarizes the counts and completeness for key clades, and
#              generates plots for visualization.
#==============================================================================

#*-----File Definitions and Setup----------------------------------------------*

COPIA_IN <- "Copia_sequences.fa.rexdb-plant.cls.tsv"
GYPSY_IN <- "Gypsy_sequences.fa.rexdb-plant.cls.tsv"

if (!file.exists(COPIA_IN) || !file.exists(GYPSY_IN)) {
  stop("Input files from TEsorter (Copia/Gypsy .cls.tsv) not found.")
}

message("Reading Copia and Gypsy classification tables...")

#-------------------------------------------------------------
# Load and Merge Copia and Gypsy classification tables
#-------------------------------------------------------------
copia <- read_tsv(COPIA_IN) %>% mutate(Superfamily = "Copia")
gypsy <- read_tsv(GYPSY_IN) %>% mutate(Superfamily = "Gypsy")

combined <- bind_rows(copia, gypsy)

#-------------------------------------------------------------
# Focus on key LTR-RT clades
#-------------------------------------------------------------
# Keep important/known clades for visualization
key_clades <- c("Athila", "Retand", "CRM", "Reina", "Tekay", "Ale", "Ivana", "Tork", "Bianca", "SIRE")

filtered <- combined %>%
  filter(Clade %in% key_clades)

#-------------------------------------------------------------
# Summarize counts (Total, Complete vs Incomplete)
#-------------------------------------------------------------
summary_tbl <- filtered %>%
  group_by(Superfamily, Clade, Complete) %>%
  summarise(count = n(), .groups = "drop") %>%
  # Ensure all Superfamily/Clade combinations are present, filling missing 'Complete' types with 0
  complete(Superfamily, Clade, Complete, fill = list(count = 0))

message("Summary table created.")

#-------------------------------------------------------------
# Plot 1: Barplot (counts per clade, complete vs incomplete)
#-------------------------------------------------------------
p1 <- ggplot(summary_tbl, aes(x = reorder(Clade, count, FUN = sum), y = count, fill = Complete)) +
  geom_bar(stat = "identity", position = "stack") +
  # Reorder Clades within each facet by total count (using tidy eval)
  facet_wrap(~Superfamily, scales = "free_x") + 
  theme_minimal(base_size = 14) +
  labs(
    title = "Distribution of Major LTR Retrotransposon Clades (Altai-5)",
    subtitle = "Counts separated by completeness (Total elements: Copia/Gypsy library)",
    x = "Clade (Ordered by total abundance)",
    y = "Number of elements",
    fill = "Complete TE"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c("Incomplete" = "#4575b4", "Complete" = "#d73027"))

ggsave("06_LTR_clade_distribution_barplot.png", p1, width = 10, height = 6, dpi = 300)
message("Barplot saved: 06_LTR_clade_distribution_barplot.png")


#-------------------------------------------------------------
# Plot 2: Pie chart showing proportion of each clade in both superfamilies
#-------------------------------------------------------------
prop_tbl <- combined %>%
  group_by(Superfamily, Clade) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(Superfamily) %>%
  mutate(percentage = count / sum(count) * 100) %>%
  ungroup() %>%
  arrange(desc(percentage))

p2 <- ggplot(prop_tbl, aes(x = "", y = percentage, fill = Clade)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +
  facet_wrap(~Superfamily) +
  theme_void(base_size = 14) +
  labs(title = "Proportion of LTR Clades within Each Superfamily (Altai-5)") +
  # Use a qualitative palette that has enough distinct colors for all clades
  scale_fill_brewer(palette = "Paired") + 
  # Add labels to the segments (optional but helpful)
  geom_text(aes(label = sprintf("%.1f%%", percentage)), 
            position = position_stack(vjust = 0.5), 
            size = 3.5, 
            color = "black")

ggsave("06_LTR_clade_proportions_piechart.png", p2, width = 10, height = 5, dpi = 300)
message("Pie chart saved: 06_LTR_clade_proportions_piechart.png")


#-------------------------------------------------------------
# Summary table export
#-------------------------------------------------------------
write_tsv(summary_tbl, "06_LTR_clade_summary_counts.tsv")
write_tsv(prop_tbl, "06_LTR_clade_proportions.tsv")
message("Summary tables exported.")