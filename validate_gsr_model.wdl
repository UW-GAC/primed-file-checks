version 1.0

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

    if (import_tables) {
        scatter (f in validate.data_files) {
            call gsr.gsr_data_report {
                input: data_file = f,
                    analysis_id = validate.analysis_id,
                    dd_url = model_url,
                    workspace_name = workspace_name,
                    workspace_namespace = workspace_namespace
            }
        }

        call gsr.summarize_data_check {
            input: file = validate.data_files,
                data_check = gsr_data_report.pass_checks,
                validation_report = gsr_data_report.validation_report
        }
    }

    output {
        File validation_report = validate.validation_report
        Array[File]? tables = validate.tables
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
          Rscript /usr/local/primed-file-checks/select_gsr_files.R \
            --table_files output_tables.tsv
        else
          echo "NULL" > data_files.txt
          echo "NULL" > md5sum.txt
          echo "NULL" > analysis_id.txt
        fi
    >>>

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("output_*_table.tsv")
        Array[File] data_files = read_lines("data_files.txt")
        Array[String] md5sum = read_lines("md5sum.txt")
        String analysis_id = read_string("analysis_id.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.2"
    }
}
