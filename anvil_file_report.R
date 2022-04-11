library(argparser)
library(AnvilDataModels)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argv <- parse_args(argp)

model_file <- "https://raw.githubusercontent.com/UW-GAC/primed_data_models/main/PRIMED_data_model_draft.tsv"

tables <- readr::read_tsv(argv$table_files, col_names=c("names", "files"), col_types = readr::cols())
params <- list(tables=setNames(tables$files, tables$names), model=model_file)

custom_render_markdown("data_model_report", argv$out_prefix, 
                       parameters=params)
