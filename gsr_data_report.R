library(argparser)
library(AnvilDataModels)
library(readr)

argp <- arg_parser("report")
argp <- add_argument(argp, "--data_file", help="tsv file with data")
argp <- add_argument(argp, "--dd_file", help="json file with GSR data dictionary")
argp <- add_argument(argp, "--dd_table_name", help="name of data dictionary table in dd_file")
argp <- add_argument(argp, "--analysis_file", help="tsv file with analysis table")
argp <- add_argument(argp, "--stop_on_fail", flag=TRUE, help="return an error code if data_file does not pass checks")
argv <- parse_args(argp)

# argv <- list(data_file="testdata/gsr_chr1.tsv",
#              dd_file="testdata/gsr_data_model.json",
#              dd_table_name="gsr_files_dd",
#              analysis_file="output_analysis_table.tsv")

# read data model
dd <- json_to_dm(argv$dd_file)
dd_table_name <- argv$dd_table_name
stopifnot(dd_table_name %in% names(dd))

# read 1000 rows for checking data against expected type
dat <- read_tsv(argv$data_file, n_max=1000)
dat <- list(dat)
names(dat) <- dd_table_name

# read analysis table to assess conditions
if (!is.na(argv$analysis_file)) {
    analysis <- read_tsv(argv$analysis_file, col_types=cols(.default=col_character()))
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

params <- list(tables=dat, model=dd)
pass <- custom_render_markdown("data_dictionary_report", "data_dictionary_validation", parameters=params)
writeLines(tolower(as.character(pass)), "pass.txt")
if (argv$stop_on_fail) {
    if (!pass) stop("data file not compatible with data model; see data_dictionary_validation.html")
}
