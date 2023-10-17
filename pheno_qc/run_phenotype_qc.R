# Set libraries
library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

# Get parameters
argp <- arg_parser("validate")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argp <- add_argument(argp, "--use_existing_tables", flag=TRUE, help="for any tables in the data model but not included in table_files, read the existing table from the AnVIL workspace for QC")

# read data model
model <- json_to_dm(argv$model_file)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")
message("tables to validate:")
print(table_files$names)

params <- list(tables=check_files, model=argv$model_file)
pass <- custom_render_markdown("phenotype_data_qc", parameters=params)