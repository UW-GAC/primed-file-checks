library(argparser)
library(AnvilDataModels)

argp <- arg_parser("report")
argp <- add_argument(argp, "--subject_file", help="tsv file with subject table")
argp <- add_argument(argp, "--sample_file", help="tsv file with sample table")
argp <- add_argument(argp, "--sample_set_file", help="tsv file with sample set table")
argp <- add_argument(argp, "--dataset_type", help="type of dataset (array, imputation, sequencing)")
argp <- add_argument(argp, "--dataset_file", help="tsv file with dataset table entry as field,value")
argp <- add_argument(argp, "--file_table_file", help="tsv file with file table")
argp <- add_argument(argp, "--model_file", help="tsv file with data model")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argv <- parse_args(argp)

# argv <- list(subject_file="testdata/subject.tsv",
#              sample_file="testdata/sample.tsv",
#              sample_set_file="testdata/sample_set.tsv",
#              dataset_type="array",
#              dataset_file="testdata/dataset.tsv",
#              file_table_file="testdata/file.tsv",
#              model_file="testdata/data_model.tsv",
#              out_prefix="test")

stopifnot(argv$dataset_type %in% c("array", "imputation", "sequencing"))
dataset_table_name <- paste0(argv$dataset_type, "_dataset")
file_table_name <- paste0(argv$dataset_type, "_file")

# read data model
model <- tsv_to_dm(argv$model_file)

# read dataset field,value pairs
fv <- readr::read_tsv(argv$dataset_file, col_types="cc")

# transpose
dataset <- transpose_field_value(fv, table_name=dataset_table_name, model=model)

# add dataset_id
dataset <- add_auto_columns(dataset, table_name=dataset_table_name, model=model)

# read file table
file <- readr::read_tsv(argv$file_table_file)

# add dataset_id
file[[paste0(dataset_table_name, "_id")]] <- dataset[[paste0(dataset_table_name, "_id")]]

# add file_id 
file <- add_auto_columns(file, table_name=file_table_name, model=model)

# write tsv files
dataset_file <- paste0(argv$out_prefix, "_dataset_table.tsv")
readr::write_tsv(dataset, dataset_file)
file_file <- paste0(argv$out_prefix, "_file_table.tsv")
readr::write_tsv(file, file_file)

# check tsv files against data model
tables <- setNames(c(argv$subject_file, argv$sample_file, argv$sample_set_file,
                     dataset_file, file_file),
                   c("subject", "sample", "sample_set", 
                     dataset_table_name, file_table_name))
params <- list(tables=tables, model=argv$model_file)
pass <- custom_render_markdown("data_model_report", argv$out_prefix, parameters=params)
writeLines(tolower(as.character(pass)), "pass.txt")

# write tsv with set of tables to import to workspace
if (pass) {
    table_files <- tibble(table=names(tables), file=tables)
    out_file <- paste0(argv$out_prefix, "_files_to_import.tsv")
    readr::write_tsv(table_files, out_file, col_names=FALSE)
}

