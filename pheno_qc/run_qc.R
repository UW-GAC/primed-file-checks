# Set libraries
library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

# setwd('/home/rstudio/primed-file-checks/pheno_qc')

# Get parameters
argp <- arg_parser(description = "data qc") 
argp <- add_argument(parser = argp, 
                     arg = "--filename", 
                     type = "character", 
                     nargs = 1,
                     help="2-column tsv file with (table name, table tsv file)")
argv <- parse_args(parser = argp)

# read tables
table_files <- read_tsv(argv$filename, col_names=c("names", "files"), col_types="cc")
message("tables to QC:")
print(table_files$names)

parameters <- list(tables=table_files)

# pass <- rmarkdown::render(output_file="template_main_qc.Rmd", input = "template_main_qc.Rmd", params=parameters, quiet=TRUE) 
