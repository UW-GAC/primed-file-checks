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

if("domain" %in% colnames(table_files)){
  table_files$table_names = table_files$domain
}

if("file_path" %in% colnames(table_files)){
  table_files$file_names = table_files$file_path
}

table_files <- table_files %>% select(table_names, file_names)

# read filepath 
path_to_rmd <- argv$path_to_rmd

gsutil_cp(table_files$file_names, ".")
table_files$file_names <- paste0(getwd(), "/", basename(table_files$file_names))

input <- paste0(path_to_rmd, "template_main_qc.Rmd")

parameters <- list(tables=table_files, path = path_to_rmd)

rmarkdown::render(input = input, params = parameters, quiet=TRUE)
file.copy(file.path(path_to_rmd, "template_main_qc.html"), "qc_report.html")

# rmarkdown::render(input = input, params=parameters, quiet=TRUE)