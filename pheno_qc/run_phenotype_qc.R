# Set libraries
library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

# Get parameters
argp <- arg_parser("data_qc") # the name of the task in the wdl
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argv <- parse(argp)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")
message("tables to QC:")
print(table_files$names)

params <- list(tables=table_files)
pass <- rmarkdown::render(output_file="main_qc.Rmd", input = "main_qc.Rmd", params=parameters, quiet=TRUE) 