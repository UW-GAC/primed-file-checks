version 1.0

workflow validate_phenotype_model {
    input {
        File phenotype_table
        Boolean harmonized
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Int? hash_id_nchar
    }

    call results {
        input: phenotype_table = phenotype_table,
               harmonized = harmonized,
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
        File phenotype_table
        Boolean harmonized
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite
        Boolean import_tables
        Int hash_id_nchar = 16
    }

    command <<<
        echo "starting prep"
        Rscript /usr/local/primed-file-checks/prep_phenotypes.R \
            --table_file ~{phenotype_table} ~{true="--harmonized" false="" harmonized} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        echo "starting validation"
        Rscript /usr/local/anvil-util-workflows/validate_data_model.R \
            --table_files output_table_files_validate.tsv \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ~{hash_id_nchar}
        if [[ "~{import_tables}" == "true" ]] && [[ "$(<pass.txt)" == "PASS" ]]
        then
          echo "starting import"
          Rscript /usr/local/anvil-util-workflows/data_table_import.R \
            --table_files output_table_files_import.tsv ~{true="--overwrite" false="" overwrite} \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        else 
          echo "no import"
        fi
        if [[ "$(<pass.txt)" == "FAIL" ]]
        then
          exit 1
        fi
    >>>

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("*_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.1.1"
    }
}
