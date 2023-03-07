version 1.0

workflow validate_gsr_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
    }

    call results {
        input: table_files = table_files,
               model_url = model_url,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    output {
        File validation_report = results.validation_report
        Array[File]? tables = results.tables
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task results {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite
        Boolean import_tables
    }

    command {
        Rscript /usr/local/primed-file-checks/prep_gsr.R \
            --table_files ${write_map(table_files)} \
            --model_file ${model_url}
        Rscript /usr/local/anvil-util-workflows/validate_data_model.R \
            --table_files output_table_files.tsv ${true="--overwrite" false="" overwrite} \
            --model_file ${model_url} ${true="--import_tables" false="" import_tables} \
            --workspace_name ${workspace_name} \
            --workspace_namespace ${workspace_namespace} \
            --stop_on_fail --use_existing_tables
    }

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("*_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.2.7"
    }
}
