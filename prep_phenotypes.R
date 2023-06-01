library(argparser)
library(AnvilDataModels)
library(dplyr)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--table_file", help="google bucket path to phenotype table file")
argp <- add_argument(argp, "--harmonized", flag=TRUE, help="flag for whether this table is harmonized or unharmonized")
argp <- add_argument(argp, "--workspace_name", help="name of AnVIL workspace to import data to")
argp <- add_argument(argp, "--workspace_namespace", help="namespace of AnVIL workspace to import data to")
argv <- parse_args(argp)

argv <- list(table_file="testdata/table_files_phenotype.tsv",
             harmonized=TRUE)

# read phenotype table
phen_table <- read_table(argv$table_file)

common_cols <- c("md5sum", "file_path", "n_subjects", "n_rows")

# make sure we have a subject table
if (argv$harmonized) {
    stopifnot(all(c(common_cols, "domain", "file_readme_path") %in% names(phen_table)))
    
    if ("subject" %in% phen_table$domain) {
        subj <- gsutil_pipe(phen_table, "rb") %>%
            filter(domain == "subject") %>%
            select(file_path) %>%
            unlist() %>%
            read_table()
    } else {
        existing_table_names <- avtables(namespace=argv$workspace_namespace, name=argv$workspace_name)$table
        if ("subject" %in% existing_table_names) {
            subj <- avtable(t, namespace=argv$workspace_namespace, name=argv$workspace_name)
        } else {
            stop("subject table must be provided if not present in workspace")
        }
    }
    
    no_subj <- filter(phen_table, domain != "subject")
} else {
    stopifnot(all(c(common_cols, "description", "file_dd_path") %in% names(phen_table)))
    
    existing_table_names <- avtables(namespace=argv$workspace_namespace, name=argv$workspace_name)$table
    if ("subject" %in% existing_table_names) {
        subj <- avtable(t, namespace=argv$workspace_namespace, name=argv$workspace_name)
    } else {
        stop("subject table must already be present in workspace; import harmonized tables first")
    }
    
    no_subj <- phen_table
}

# check subject id in file
if (nrow(no_subj) > 0) {
for (i in 1:nrow(no_subj)) {
    message("checking subjects in file ", no_subj$file_path)
    phen <- gsutil_pipe(no_subj$file_path[i], "rb") %>%
        read_tsv()
    if (!("subject_id" %in% names(phen))) {
        stop("no subject_id column found")
    }
    extra <- setdiff(phen$subject_id, subj$subject_id)
    if (length(extra) > 0) {
        stop("subject_id values not present in subject table: ", paste(extra, collapse=", "))
    }
    ns1 <- no_subj$n_subjects[i]
    ns2 <- length(unique(phen$subject_id))
    if (ns1 != ns2) {
        stop("reported ", ns1, " subjects but counted ", ns2)
    }
    nr1 <- no_subj$n_rows[i]
    nr2 <- nrow(phen)
    if (nr1 != nr2) {
        stop("reported ", nr1, " rows but counted ", nr2)
    }
}
}

# tables to validate
if (argv$harmonized) {
    table_files <- phen_table %>%
        select(name=domain, file=file_path) %>%
        bind_rows(tibble(name = "phenotype_harmonized",
                         file = argv$table_file))
} else {
    table_files <- tibble(name = "phenotype_unharmonized",
                          file = argv$table_file)
}
write_tsv(table_files, "output_table_files_validate.tsv", col_names=FALSE)

# tables to import
if (argv$harmonized) {
    table_files <- table_files %>%
        filter(name %in% c("subject", "population_descriptor", 
                           "phenotype_harmonized"))
} else {
    table_files <- table_files %>%
        filter(name %in% c("phenotype_unharmonized"))
}
write_tsv(table_files, "output_table_files_import.tsv", col_names=FALSE)
