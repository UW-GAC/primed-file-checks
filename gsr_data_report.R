library(argparser)
library(AnvilDataModels)

argp <- arg_parser("report")
argp <- add_argument(argp, "--dd_file", help="json file with GSR data dictionary")
argp <- add_argument(argp, "--analysis_file", help="tsv file with analysis table (output by gsr_report)")
argp <- add_argument(argp, "--out_prefix", help="output prefix")
argv <- parse_args(argp)

# argv <- list(data_file="testdata/gsr_chr1.tsv",
#              dd_file="testdata/gsr_dd.json",
#              analysis_file="test_analysis_table.tsv",
#              out_prefix="test")

# read data model
dd <- json_to_dm(argv$dd_file)

# read 1000 rows for checking data against expected type
dat <- readr::read_tsv(argv$data_file, n_max=1000)
dat <- list(dat)
names(dat) <- names(dd)

# read file to assess conditions
if (!is.na(argv$analysis_file)) {
    analysis <- readr::read_tsv(argv$analysis_file)
    # parse conditions and add cols to 'required' as necessary
    req <- character()
    cond <- attr(dd[[1]], "conditions")
    for (c in names(cond)) {
        p <- AnvilDataModels:::.parse_condition(cond[[c]])
        if (analysis[[p$column]] == p$value) {
            req <- c(req, c)
        }
    }
    if (length(req) > 0) {
        req <- unique(c(attr(dd[[1]], "required"), req))
        # can't update attributes on a dm object
        tmp <- dd[[1]]
        attr(tmp, "required") <- req
        # remove conditions so columns aren't listed twice in check
        attr(tmp, "conditions") <- character()
        tmp <- list(tmp)
        names(tmp) <- names(dd)
        dd <- dm::as_dm(tmp)
    }
}

outfile <- paste0(argv$out_prefix, ".txt")
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
