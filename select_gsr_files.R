library(argparser)
library(AnvilDataModels)
library(readr)

argp <- arg_parser("select")
argp <- add_argument(argp, "--file_table", help="tsv file with file table")
argv <- parse_args(argp)

file_table <- read_tsv(argv$file_table)

data_files <- file_table$file_path
writeLines(data_files, "data_files.txt")

md5 <- file_table$md5sum
writeLines(md5, "md5sum.txt")
