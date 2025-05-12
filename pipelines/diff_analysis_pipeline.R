# Read DMR data (assuming the file has a header row)
dmr_8_cell_lt_ICM <- read.table("C:/Users/natal/Downloads/fastqc_files/diff_analysis/dmr-ICM_lt-8_cell_gene_ids.txt", header = FALSE,
                                  col.names = c("start_loci_dmr", "end_loci_dmr", "dmreads", "start_loci_gene", "end_loci_gene", "gene_id"),
                                  colClasses = c("integer", "integer", "integer", "integer", "integer", "character"))

# Load gene annotation package
library(org.Mm.eg.db)

# Extract relevant portion of gene ID for matching
ens_str <- substr(dmr_8_cell_lt_ICM$gene_id, 1, 18)

# Get gene symbols using gene IDs (assuming unique gene symbols)
dmr_8_cell_lt_ICM$gene_name <- mapIds(org.Mm.eg.db, keys = ens_str, column = "SYMBOL",
                                        keytype = "ENSEMBL", multiVals = "first")
# Load dplyr package for data manipulation
library(dplyr)

# Filter DMR data: remove duplicates and rows with missing values
dmr_8_cell_lt_ICM_filtered <- dmr_8_cell_lt_ICM %>%
  distinct() %>%
  filter(!duplicated(gene_name)) %>%
  na.omit()

# Sort dmr genes based on methylation
dmr_8_cell_lt_ICM_sorted <- dmr_8_cell_lt_ICM_filtered[order(dmr_8_cell_lt_ICM_filtered$dmreads, decreasing = TRUE), ]

# Subset the first 50 genes
dmr_top50 <- dmr_8_cell_lt_ICM_sorted[1:50, ]

# Save the dmr_top20 object as a table
write.table(dmr_top50, file = "dmr_top50_table.txt", sep = "\t", quote = FALSE, row.names = FALSE)

library(ggplot2)

# Subset the first 20 genes
dmr_top20 <- dmr_8_cell_lt_ICM_sorted[1:20, ]

# Create the histogram using ggplot2
ggplot(dmr_top20, aes(x = gene_name, y = dmreads)) +
  geom_bar(stat = "identity", fill = "steelblue", color = "white") +
  labs(title = "Histogram of Genes closest to Differentially Methylated Regions",
       x = "Gene Name", y = "dmreads") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# Save the plot as an image
ggsave("dmr_top20.png")

