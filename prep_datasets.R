library(argparser)
library(AnvilDataModels)
library(dplyr)
library(tidyr)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argv <- parse_args(argp)

# argv <- list(table_files="testdata/table_files_dataset.tsv",
#              model_file="testdata/data_model.json")

# read data model
model <- json_to_dm(argv$model_file)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types = cols())

# identify datasets
dataset_files <- table_files %>%
    filter(grepl("_dataset$", names) | grepl("_file$", names)) %>%
    separate(names, into=c("type", "table"), sep="_") %>%
    pivot_wider(names_from=table, values_from=files)

if (nrow(dataset_files) > 0) {
    for (i in 1:nrow(dataset_files)) {
        type <- dataset_files$type[i]
        dataset_table_name <- paste0(type, "_dataset")
        file_table_name <- paste0(type, "_file")
        
        # read dataset field,value pairs
        fv <- read_tsv(dataset_files$dataset[i], col_types="cc")
        
        # transpose
        dataset <- transpose_field_value(fv, table_name=dataset_table_name, model=model)
        
        # add dataset_id
        dataset <- add_auto_columns(dataset, table_name=dataset_table_name, model=model,
                                    error_on_missing=FALSE)
        
        # read file table
        file <- read_tsv(dataset_files$file[i], show_col_types=FALSE)
        
        # add dataset_id
        dataset_id <- paste0(dataset_table_name, "_id")
        file[[dataset_id]] <- dataset[[dataset_id]]
        
        # add file_id 
        file <- add_auto_columns(file, table_name=file_table_name, model=model,
                                 error_on_missing=FALSE)
        
        # write tsv files
        dataset_file <- paste0("output_", type, "_dataset_table.tsv")
        write_tsv(dataset, dataset_file)
        file_file <- paste0("output_", type, "_file_table.tsv")
        write_tsv(file, file_file)
        
        table_files$files[table_files$names == dataset_table_name] <- dataset_file
        table_files$files[table_files$names == file_table_name] <- file_file
    }
}

# write new version of table_files
write_tsv(table_files, "output_table_files.tsv", col_names=FALSE)
