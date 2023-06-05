version 1.0

workflow validate_phenotype_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Int? hash_id_nchar
    }

    call results {
        input: table_files = table_files,
               model_url = model_url,
               hash_id_nchar = hash_id_nchar,
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
        Int hash_id_nchar = 16
    }

    command <<<
        git clone -b phen_tables https://github.com/UW-GAC/primed-file-checks.git /usr/local/primed-file-checks-2
        set -e
        echo "starting prep"
        Rscript /usr/local/primed-file-checks/prep_phenotypes.R \
            --table_files ~{write_map(table_files)} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        echo "starting validation"
        Rscript /usr/local/primed-file-checks-2/validate_data_model.R \
            --table_files output_table_files_validate.tsv \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ~{hash_id_nchar}
        #cat pass.txt
        mv data_model_validation.html phenotype_table_validation.html
        if [[ "~{import_tables}" == "true" ]]
        then
          echo "starting import"
          Rscript /usr/local/primed-file-checks-2/validate_data_model.R \
            --table_files output_table_files_import.tsv ~{true="--overwrite" false="" overwrite} \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ~{hash_id_nchar}
        #cat pass.txt
        else
            echo "no import"
        fi
    >>>

    output {
        File validation_report = "phenotype_table_validation.html"
        File validation_report_2 = "data_model_validation.html"
        #Array[File]? tables = glob("*_table.tsv")
        Array[File]? tables = glob("output_*.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.1.1"
    }
}
