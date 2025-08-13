version 1.0

import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/check_md5.wdl" as md5
import "gsr_data_report.wdl" as gsr

workflow validate_gsr_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Int? hash_id_nchar
    }

    call validate {
        input: table_files = table_files,
               model_url = model_url,
               hash_id_nchar = hash_id_nchar,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    scatter (pair in zip(validate.analysis_tables, validate.file_tables)) {
        call select_gsr_files {
            input: file_table = pair.right
        }

        scatter (data_pair in zip(select_gsr_files.data_files, select_gsr_files.md5sum)) {
            call md5.md5check {
                input: file = data_pair.left,
                    md5sum = data_pair.right
            }
        }

        scatter (f in select_gsr_files.data_files) {
            call gsr.validate_data {
                input: data_file = f,
                    analysis_file = pair.left,
                    dd_table_name = sub(basename(pair.left, "_analysis_table.tsv"), "output_", "") + "_files_dd",
                    dd_url = model_url
            }
        }
    }

    call md5.summarize_md5_check {
        input: file = flatten(select_gsr_files.data_files),
            md5_check = flatten(md5check.md5_check)
    }

    call gsr.summarize_data_check {
        input: file = flatten(select_gsr_files.data_files),
            data_check = flatten(validate_data.pass_checks),
            validation_report = flatten(validate_data.validation_report)
    }

    output {
        File validation_report = validate.validation_report
        Array[File] tables = flatten([validate.analysis_tables, validate.file_tables])
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

task validate {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite
        Boolean import_tables
        Int hash_id_nchar = 16
    }

    command <<<
        set -e
        echo "starting prep"
        Rscript /usr/local/primed-file-checks/prep_gsr.R \
            --table_files ~{write_map(table_files)} \
            --model_file ~{model_url} \
            --hash_id_nchar ~{hash_id_nchar}
        echo "starting validation"
        Rscript /usr/local/anvil-util-workflows/validate_data_model.R \
            --table_files output_table_files.tsv \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ~{hash_id_nchar}
        if [[ "~{import_tables}" == "true" ]]
        then
          echo "starting import"
          Rscript /usr/local/anvil-util-workflows/data_table_import.R \
            --table_files output_tables.tsv \
            --model_file ~{model_url} ~{true="--overwrite" false="" overwrite} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        fi
    >>>

    output {
        File validation_report = "data_model_validation.html"
        Array[File] analysis_tables = glob("output_*_analysis_table.tsv")
        Array[File] file_tables = glob("output_*_file_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.5.1-1"
        disks: "local-disk 16 SSD"
        memory: "8G"
    }
}


task select_gsr_files {
    input {
        File file_table
    }

    #Rscript /usr/local/primed-file-checks/select_gsr_files.R --file_table ~{file_table}
    command <<<
        R << RSCRIPT
            library(dplyr)
            library(readr)
            file_table <- read_tsv("~{file_table}")
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
