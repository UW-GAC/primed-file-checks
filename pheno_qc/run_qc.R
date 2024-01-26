# Set libraries
library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

# Rscript run_qc.R --filename data_qc.tsv --filepath /home/rstudio/primed-file-checks/pheno_qc/

# Get parameters
argp <- arg_parser(description = "data qc") 
argp <- add_argument(parser = argp, 
                     arg = "--filename", 
                     type = "character", 
                     nargs = 1,
                     help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(parser = argp, 
                     arg = "--filepath", 
                     type = "character", 
                     nargs = 1,
                     help="rmd filepath")
argv <- parse_args(parser = argp)

# read tables
table_files <- read_tsv(argv$filename, col_names=TRUE, col_types="cc")

# read filepath 
filepath <- argv$filepath

message("tables to QC:")
print(table_files$table_names)

message("filepath:")
print(filepath)

input <- paste0(filepath, "template_main_qc.Rmd")

parameters <- list(tables=table_files, path = filepath)

rmarkdown::render(input = input, params=parameters, quiet=TRUE)
