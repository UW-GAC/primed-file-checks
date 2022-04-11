library(argparser)
library(AnvilDataModels)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_files", nargs=Inf, help="tsv files with data tables")
argp <- add_argument(argp, "--table_names", nargs=Inf, help="tsv file with data model")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argv <- parse_args(argp)

stopifnot(length(argv$table_files) == length(argv$table_names))

model_file <- "https://raw.githubusercontent.com/UW-GAC/primed_data_models/main/PRIMED_data_model_draft.tsv"

params <- list(tables=setNames(argv$table_files, argv$table_names),
               model=model_file)

custom_render_markdown("data_model_report", argv$out_prefix, 
                       parameters=params)
