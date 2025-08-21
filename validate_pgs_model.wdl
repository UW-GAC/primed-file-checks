version 1.0

import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/validate_data_model.wdl" as validate
import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/check_md5.wdl" as md5
import "gsr_data_report.wdl" as gsr

workflow validate_pgs_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Boolean check_bucket_paths = true
        Int? hash_id_nchar
    }

    call validate.validate {
        input: table_files = table_files,
               model_url = model_url,
               hash_id_nchar = hash_id_nchar,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables,
               check_bucket_paths = check_bucket_paths
    }

    # need this because validate.tables is optional but input to select_pgs_files is required
    Array[File] val_tables = select_first([validate.tables, ""])

    if (defined(validate.tables)) {
        call select_pgs_files {
            input: validated_table_files = val_tables
        }

        scatter (data_pair in zip(select_pgs_files.data_files, select_pgs_files.md5sum)) {
            call md5.md5check {
                input: file = data_pair.left,
                    md5sum = data_pair.right
            }
        }

        scatter (f in select_pgs_files.data_files) {
            call gsr.validate_data {
                input: data_file = f,
                    dd_table_name = "pgs_files_dd",
                    dd_url = model_url
            }
        }

        call md5.summarize_md5_check {
            input: file = select_pgs_files.data_files,
                md5_check = md5check.md5_check
        }

        call gsr.summarize_data_check {
            input: file = select_pgs_files.data_files,
                data_check = validate_data.pass_checks,
                validation_report = validate_data.validation_report
        }
    }

    output {
        File validation_report = validate.validation_report
        Array[File]? tables = validate.tables
        String? md5_check_summary = summarize_md5_check.summary
        File? md5_check_details = summarize_md5_check.details
        String? data_report_summary = summarize_data_check.summary
        File? data_report_details = summarize_data_check.details
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task select_pgs_files {
    input {
        Array[File] validated_table_files
    }

    command <<<
        R << RSCRIPT
            library(dplyr)
            library(readr)
            tables <- readLines('~{write_lines(validated_table_files)}')
            names(tables) <- sub('^output_', '', sub('_table.tsv', '', basename(tables)))
            file_table <- read_tsv(tables['pgs_file'])
            file_table <- filter(file_table, file_type == "data")
            data_files <- file_table[["file_path"]]
            writeLines(data_files, "data_files.txt")
            md5 <- file_table[["md5sum"]]
            writeLines(md5, "md5sum.txt")
        RSCRIPT
    >>>

    output {
        Array[File] data_files = read_lines("data_files.txt")
        Array[String] md5sum = read_lines("md5sum.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.5.1-1"
        disks: "local-disk 16 SSD"
        memory: "8G"
    }
}
