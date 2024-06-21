library(argparser)
library(AnvilDataModels)
library(dplyr)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argp <- add_argument(argp, "--hash_id_nchar", default=16, help="number of characters in automatically generated ids")
argv <- parse_args(argp)

# argv <- list(table_files="testdata/table_files_gsr.tsv",
#              model_file="testdata/gsr_data_model.json",
#              hash_id_nchar=16)

# read data model
model <- json_to_dm(argv$model_file)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")

# identify analyses
analysis_files <- table_files %>%
    filter(grepl("_analysis$", names) | grepl("_file$", names)) %>%
    separate(names, into=c("type", "table"), sep="_") %>%
    pivot_wider(names_from=table, values_from=files)

if (nrow(analysis_files == 0)) stop("no valid analysis/file table pairs found")
for (i in 1:nrow(analysis_files)) {
    type <- analysis_files$type[i]
    analysis_table_name <- paste0(type, "_analysis")
    file_table_name <- paste0(type, "_file")
    
    # read analysis field,value pairs
    fv <- read_tsv(analysis_files$analysis[i], col_types=cols(.default=col_character()))
    
    # transpose
    transpose_fv <- function(fv) {
        stopifnot(setequal(names(fv), c("field", "value")))
        lapply(setNames(1:nrow(fv), fv$field), function(i) {
            v <- fv$value[i]
            return(v)
        }) %>%
            bind_cols()
    }
    analysis <- transpose_fv(fv)
    
    # add analysis_id
    analysis_id <- hash_id(paste(analysis, collapse=""), nchar=argv$hash_id_nchar)
    analysis <- bind_cols(analysis_id=analysis_id, analysis)
    
    # read file table
    file <- read_tsv(analysis_files$file[i], col_types=cols(.default=col_character()))
    
    # add analysis_id
    file <- bind_cols(analysis_id=analysis$analysis_id, file)
    
    # add file_id 
    file <- add_auto_columns(file, table_name=file_table_name, model=model,
                             error_on_missing=FALSE, nchar=argv$hash_id_nchar)
    
    # write tsv files
    analysis_file <- paste0("output_", type, "_analysis_table.tsv")
    write_tsv(analysis, analysis_file)
    file_file <- paste0("output_", type, "_file_table.tsv")
    write_tsv(file, file_file)
    
    table_files$files[table_files$names == analysis_table_name] <- analysis_file
    table_files$files[table_files$names == file_table_name] <- file_file
}

# write new version of table_files
write_tsv(table_files, "output_table_files.tsv", col_names=FALSE)
