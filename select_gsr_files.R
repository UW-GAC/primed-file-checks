library(argparser)
library(AnvilDataModels)
library(readr)
library(dplyr)
library(tidyr)

argp <- arg_parser("select")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argv <- parse_args(argp)

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")
tables <- read_data_tables(table_files$files, table_names=table_files$names)
stopifnot(all(grepl("analysis$", names(tables)) | grepl("file$", names(tables))))

analyses <- table_files %>%
    separate_wider_delim(names, delim="_", names=c("type", "table")) %>%
    pivot_wider(names_from=table, values_from=files)

data_files <- list()
analysis_files <- list()
md5 <- list()
for (t in analyses$type) {
    file_table_name <- paste0(t, "_file")
    md5[[t]] <- tables[[file_table_name]]$md5sum
    data_files[[t]] <- tables[[file_table_name]]$file_path
    analysis_files[[t]] <- analyses %>%
        filter(type == t) %>%
        select(analysis) %>%
        unlist() %>%
        rep(length(data_files[[t]]))
}

writeLines(unlist(md5), "md5sum.txt")
writeLines(unlist(data_files), "data_files.txt")
writeLines(unlist(analysis_files), "analysis_files.txt")
