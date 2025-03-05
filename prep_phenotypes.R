library(argparser)
library(AnVIL)
library(AnvilDataModels)
library(dplyr)
library(readr)
library(jsonlite)

argp <- arg_parser("prep")
argp <- add_argument(argp, "--table_files", help="2-column tsv file with (table name, table tsv file)")
argp <- add_argument(argp, "--model_file", help="json file with data model")
argp <- add_argument(argp, "--workspace_name", help="name of AnVIL workspace to import data to")
argp <- add_argument(argp, "--workspace_namespace", help="namespace of AnVIL workspace to import data to")
argv <- parse_args(argp)

# argv <- list(table_files="testdata/table_files_phenotype.tsv", 
#              model_file="testdata/data_model_phen.json",
#              workspace_name="PRIMED_genotype_test", workspace_namespace="primed-stephanie")

# read data model
model <- fromJSON(argv$model_file)
table_versions <- model$tables %>%
    select(table, data_model_version=version) %>%
    filter(!is.na(data_model_version))

# read tables
table_files <- read_tsv(argv$table_files, col_names=c("names", "files"), col_types="cc")

stopifnot(all(table_files$names %in% c("subject", "phenotype_harmonized", "phenotype_unharmonized")))

get_table <- function(x) {
    table_files %>%
        filter(names == x) %>%
        select(files) %>%
        unlist() %>%
        read_tsv(col_types=cols(.default=col_character()))
}

# make sure we have a subject table
if ("subject" %in% table_files$names) {
    subj <- get_table("subject")
} else {
    existing_table_names <- avtables(namespace=argv$workspace_namespace, name=argv$workspace_name)$table
    if ("subject" %in% existing_table_names) {
        subj <- avtable("subject", namespace=argv$workspace_namespace, name=argv$workspace_name)
    } else {
        stop("subject table must be provided if not present in workspace")
    }
}

# check subject id in files
check_subject_id <- function(phen_table) {
    for (i in 1:nrow(phen_table)) {
        message("checking subjects in file ", phen_table$file_path)
        phen <- read_tsv(phen_table$file_path[i], col_types=cols(.default=col_character()))
        if (!("subject_id" %in% names(phen))) {
            stop("no subject_id column found")
        }
        extra <- setdiff(phen$subject_id, subj$subject_id)
        if (length(extra) > 0) {
            stop("subject_id values not present in subject table: ", paste(extra, collapse=", "))
        }
        ns1 <- phen_table$n_subjects[i]
        ns2 <- length(unique(phen$subject_id))
        if (ns1 != ns2) {
            stop("reported ", ns1, " subjects but counted ", ns2)
        }
        nr1 <- phen_table$n_rows[i]
        nr2 <- nrow(phen)
        if (nr1 != nr2) {
            stop("reported ", nr1, " rows but counted ", nr2)
        }
    }
}


# columns in common between harmonized and unharmonized tables
common_cols <- c("md5sum", "file_path", "n_subjects", "n_rows")

# tables to validate - to be updated below
validate_files <- table_files

if ("phenotype_harmonized" %in% table_files$names) {
    # read phenotype table
    phen_table <- get_table("phenotype_harmonized")
    stopifnot(all(c(common_cols, "domain", "file_readme_path") %in% names(phen_table)))
    
    # add model version
    phen_table <- phen_table %>%
        left_join(table_versions, by=c("domain"="table"))
    outfile <- "output_phenotype_harmonized.tsv"
    write_tsv(phen_table, outfile)
    table_files$files[table_files$names == "phenotype_harmonized"] <- outfile
    
    # copy files to local instance
    gsutil_cp(phen_table$file_path, ".")
    phen_table$file_path <- basename(phen_table$file_path)
    
    # check subject_id in tables
    check_subject_id(phen_table)
    
    # tables to validate - add harmonized tables
    validate_files <- phen_table %>%
        select(names=domain, files=file_path) %>%
        bind_rows(table_files)
}


if ("phenotype_unharmonized" %in% table_files$names) {
    # read phenotype table
    phen_table <- get_table("phenotype_unharmonized")
    stopifnot(all(c(common_cols, "description", "file_dd_path") %in% names(phen_table)))
    
    # copy files to local instance
    gsutil_cp(phen_table$file_path, ".")
    phen_table$file_path <- basename(phen_table$file_path)
    
    # check subject_id
    check_subject_id(phen_table)
}


write_tsv(validate_files, "output_table_files_validate.tsv", col_names=FALSE)
