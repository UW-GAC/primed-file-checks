library(argparser)
library(AnvilDataModels)
library(readr)

argp <- arg_parser("select")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argv <- parse_args(argp)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")
tables <- read_data_tables(table_files$files, table_names=table_files$names)
stopifnot(setequal(names(tables_files), c("analysis", "gsr_file")))

analysis_id <- tables[["analysis"]]$analysis_id
stopifnot(length(analysis_id) == 1)
writeLines(analysis_id, "analysis_id.txt")

data_files <- tables[["gsr_file"]]$file_path
writeLines(data_files, "data_files.txt")
