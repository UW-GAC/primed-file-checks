library(argparser)
library(AnvilDataModels)
library(AnVIL)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--data_file", help="tsv file with data")
argp <- add_argument(argp, "--dd_file", help="json file with GSR data dictionary")
argp <- add_argument(argp, "--analysis_id", help="identifier for analysis in the analysis table")
argp <- add_argument(argp, "--workspace_name", help="name of AnVIL workspace to read analysis table from")
argp <- add_argument(argp, "--workspace_namespace", help="namespace of AnVIL workspace to read analysis table from")
argv <- parse_args(argp)

# argv <- list(data_file="testdata/gsr_chr1.tsv",
#              dd_file="testdata/gsr_dd.json")

# read data model
dd <- json_to_dm(argv$dd_file)
dd_table_name <- "gsr_files_dd"
stopifnot(dd_table_name %in% names(dd))

# read 1000 rows for checking data against expected type
dat <- read_tsv(argv$data_file, n_max=1000)
dat <- list(dat)
names(dat) <- dd_table_name

# read analysis table to assess conditions
if (!is.na(argv$workspace_name) & !is.na(argv$workspace_namespace)) {
    analysis <- avtable("analysis", namespace=argv$workspace_namespace, name=argv$workspace_name) %>%
        filter(analysis_id == argv$analysis_id)
    # parse conditions and add cols to 'required' as necessary
    req <- character()
    cond <- attr(dd[[dd_table_name]], "conditions")
    for (c in names(cond)) {
        p <- AnvilDataModels:::.parse_condition(cond[[c]])
        if (analysis[[p$column]] == p$value) {
            req <- c(req, c)
        }
    }
    if (length(req) > 0) {
        req <- unique(c(attr(dd[[dd_table_name]], "required"), req))
        # can't update attributes on a dm object
        tmp <- dd[[dd_table_name]]
        attr(tmp, "required") <- req
        # remove conditions so columns aren't listed twice in check
        attr(tmp, "conditions") <- character()
        tmp <- list(tmp)
        names(tmp) <- dd_table_name
        dd <- dm::as_dm(tmp)
    }
}

outfile <- "data_dictionary_validation.txt"
con <- file(outfile, "w")

pass <- TRUE
chk <- check_column_names(dat, dd)
res <- parse_column_name_check(chk)
if (nrow(res) > 0) {
    if (length(chk[[1]]$missing_required_columns) > 0) pass <- FALSE
    writeLines(knitr::kable(res[,-1]), con)
    writeLines("\n", con)
}

chk <- check_column_types(dat, dd)
res <- parse_column_type_check(chk)
if (nrow(res) > 0) {
    pass <- FALSE
    writeLines(knitr::kable(res[,-1]), con)
}

close(con)

writeLines(tolower(as.character(pass)), "pass.txt")
