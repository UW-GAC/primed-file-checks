library(argparser)
library(AnvilDataModels)

argp <- arg_parser("report")
argp <- add_argument(argp, "--analysis_file", help="tsv file with analysis table entry as field,value")
argp <- add_argument(argp, "--file_table_file", help="tsv file with file table")
#argp <- add_argument(argp, "--dd_file", help="tsv file with data dictionary for GSR files")
argp <- add_argument(argp, "--model_file", help="tsv file with data model")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argv <- parse_args(argp)

# argv <- list(analysis_file="testdata/gsr_analysis_table.tsv",
#              file_table_file="testdata/gsr_file.tsv",
#              dd_file="testdata/gsr_dd.tsv",
#              model_file="testdata/gsr_data_model.tsv",
#              out_prefix="test")

# read data model
model <- tsv_to_dm(argv$model_file)

# read analysis field,value pairs
fv <- readr::read_tsv(argv$analysis_file, col_types="cc")

# transpose
analysis <- transpose_field_value(fv, table_name="analysis", model=model)

# add primed_gwas_id
gwas_id <- hash_id(paste0(analysis$reported_trait,
                          analysis$outcome_type,
                          analysis$num_individuals,
                          analysis$num_variants))

analysis <- dplyr::bind_cols(primed_gwas_id=gwas_id, analysis)

# read file table
file <- readr::read_tsv(argv$file_table_file)

# add primed_gwas_id
file <- dplyr::bind_cols(primed_gwas_id=gwas_id, file)

# write tsv files
analysis_file <- paste0(argv$out_prefix, "_analysis_table.tsv")
readr::write_tsv(analysis, analysis_file)
file_file <- paste0(argv$out_prefix, "_file_table.tsv")
readr::write_tsv(file, file_file)

# check tsv files (analysis and file) against data model
params <- list(tables=c(analysis=analysis_file, file=file_file), model=argv$model_file)
pass <- custom_render_markdown("data_model_report", argv$out_prefix, parameters=params)

## check that files in file table exist?
## prepend bucket path to file_path column? (before or after checks?)

## create "data model" from DD?
## check that data files agree with DD? read first few rows?

writeLines(tolower(as.character(pass)), "pass.txt")

