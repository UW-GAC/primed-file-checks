library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(dplyr)
library(tidyr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--dataset_type", help="type of dataset (array, imputation, sequencing)")
argp <- add_argument(argp, "--dataset_file", help="tsv file with dataset table entry as field,value")
argp <- add_argument(argp, "--file_table_file", help="tsv file with file table")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argp <- add_argument(argp, "--workspace_name", help="name of AnVIL workspace to import data to")
argp <- add_argument(argp, "--workspace_namespace", help="namespace of AnVIL workspace to import data to")
argv <- parse_args(argp)

# argv <- list(dataset_type="array",
#              dataset_file="testdata/dataset.tsv",
#              file_table_file="testdata/file.tsv",
#              model_file="testdata/data_model.json")

stopifnot(argv$dataset_type %in% c("array", "imputation", "sequencing"))
dataset_table_name <- paste0(argv$dataset_type, "_dataset")
file_table_name <- paste0(argv$dataset_type, "_file")

# read data model
model <- json_to_dm(argv$model_file)

# read dataset field,value pairs
fv <- readr::read_tsv(argv$dataset_file, col_types="cc")

# transpose
dataset <- transpose_field_value(fv, table_name=dataset_table_name, model=model)

# add dataset_id
dataset <- add_auto_columns(dataset, table_name=dataset_table_name, model=model,
                            error_on_missing=FALSE)

# read file table
file <- readr::read_tsv(argv$file_table_file)

# add dataset_id
file[[paste0(dataset_table_name, "_id")]] <- dataset[[paste0(dataset_table_name, "_id")]]

# add file_id 
file <- add_auto_columns(file, table_name=file_table_name, model=model,
                         error_on_missing=FALSE)

# write tsv files
dataset_file <- paste0(argv$out_prefix, "_dataset_table.tsv")
readr::write_tsv(dataset, dataset_file)
file_file <- paste0(argv$out_prefix, "_file_table.tsv")
readr::write_tsv(file, file_file)

# read existing tables
subject <- avtable("subject", namespace=argv$workspace_namespace, name=argv$workspace_name)
sample <- avtable("sample", namespace=argv$workspace_namespace, name=argv$workspace_name)
sample_set <- avtable("sample_set", namespace=argv$workspace_namespace, name=argv$workspace_name) %>%
    select(sample_set_id, samples.items) %>% 
    unnest(samples.items) %>%
    select(sample_set_id, sample_id=entityName)

readr::write_tsv(subject, "tmp_subject.tsv")
readr::write_tsv(sample, "tmp_sample.tsv")
readr::write_tsv(sample_set, "tmp_sample_set.tsv")

# check tsv files against data model
table_files <- setNames(c("tmp_subject.tsv", "tmp_sample.tsv", "tmp_sample_set.tsv",
                     dataset_file, file_file),
                   c("subject", "sample", "sample_set", 
                     dataset_table_name, file_table_name))
params <- list(tables=table_files, model=argv$model_file)
pass <- custom_render_markdown("data_model_report", "pre_import_check", parameters=params)
if (!pass) stop("table_files not compatible with data model; see pre_import_check.html")

# read tables
tables <- read_data_tables(table_files[c(dataset_table_name, file_table_name)])

for (t in c(dataset_table_name, file_table_name)) {
    anvil_import_table(tables[[t]], table_name=t, model=model, overwrite=argv$overwrite,
                       namespace=argv$workspace_namespace, name=argv$workspace_name)
}
