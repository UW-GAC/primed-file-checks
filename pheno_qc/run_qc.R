# Set libraries
library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

# Rscript run_qc.R --data_file data_qc.tsv --path_to_rmd /home/rstudio/primed-file-checks/pheno_qc/

# Get parameters
argp <- arg_parser(description = "data qc") 
argp <- add_argument(parser = argp, 
                     arg = "--data_file", 
                     type = "character", 
                     nargs = 1,
                     help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(parser = argp, 
                     arg = "--path_to_rmd", 
                     type = "character", 
                     nargs = 1,
                     help="rmd filepath")
argv <- parse_args(parser = argp)

# read tables
table_files <- read_tsv(argv$data_file, col_names=TRUE, col_types="cc")

# read filepath 
path_to_rmd <- argv$path_to_rmd

message("tables to QC:")
print(table_files$table_names)

message("path to rmd:")
print(path_to_rmd)

input <- paste0(path_to_rmd, "template_main_qc.Rmd")

parameters <- list(tables=table_files, path = path_to_rmd)

file.copy(file.path(path_to_rmd, "template_main_qc.Rmd"), "qc_report.Rmd")
rmarkdown::render(input = "qc_report.Rmd", params=parameters, quiet=TRUE)

# rmarkdown::render(input = input, params=parameters, quiet=TRUE)