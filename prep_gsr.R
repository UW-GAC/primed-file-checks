library(argparser)
library(AnvilDataModels)
library(dplyr)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argv <- parse_args(argp)

# argv <- list(table_files="testdata/table_files_gsr.tsv",
#              model_file="testdata/gsr_data_model.json")

# read data model
model <- json_to_dm(argv$model_file)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types = cols())

# read analysis field,value pairs
analysis_file <- table_files$files[table_files$names == "analysis"]
if (length(analysis_file) == 0) stop("analysis table not found in table_files")
fv <- read_tsv(analysis_file, col_types="cc")

# transpose
analysis <- transpose_field_value(fv, table_name="analysis", model=model)

# add analysis_id
analysis_id <- hash_id(paste(analysis, collapse=""))
analysis <- bind_cols(analysis_id=analysis_id, analysis)

# read file table
file_file <- table_files$files[table_files$names == "gsr_file"]
if (length(file_file) == 0) stop("gsr_file table not found in table_files")
file <- read_tsv(file_file, show_col_types=FALSE)

# add analysis_id
file <- bind_cols(analysis_id=analysis$analysis_id, file)

# add file_id 
file <- add_auto_columns(file, table_name="gsr_file", model=model,
                         error_on_missing=FALSE)

# write tsv files
analysis_file <- "output_analysis_table.tsv"
write_tsv(analysis, analysis_file)
file_file <- "output_gsr_file_table.tsv"
write_tsv(file, file_file)

# write new version of table_files
table_files <- tibble(c("analysis", "gsr_file"), c(analysis_file, file_file))
write_tsv(table_files, "output_table_files.tsv", col_names=FALSE)
