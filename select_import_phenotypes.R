library(argparser)
library(AnVIL)
library(AnvilDataModels)
library(dplyr)
library(readr)

argp <- arg_parser("select")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argv <- parse_args(argp)

# argv <- list(table_files="testdata/table_files_phenotype.tsv")

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")

# tables to import
import_files <- table_files %>%
    filter(names %in% c("subject", "population_descriptor", 
                        "phenotype_harmonized", "phenotype_unharmonized"))

write_tsv(import_files, "output_table_files_import.tsv", col_names=FALSE)
