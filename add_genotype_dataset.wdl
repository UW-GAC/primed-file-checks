version 1.0

workflow add_genotype_dataset {
    input {
        String dataset_type
        File dataset_file
        File file_table_file
        String model_url
        String out_prefix = "report"
        String workspace_name
        String workspace_namespace
    }

    call results {
        input: dataset_type = dataset_type,
               dataset_file = dataset_file,
               file_table_file = file_table_file,
               model_url = model_url,
               out_prefix = out_prefix,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace
    }

    output {
        File file_report = results.file_report
        Array[File]? tables = results.tables
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task results{
    input {
        String dataset_type
        File dataset_file
        File file_table_file
        String model_url
        String out_prefix
        String workspace_name
        String workspace_namespace
    }

    command {
        Rscript /usr/local/primed-file-checks/add_genotype_dataset.R \
            --dataset_type ${dataset_type} \
            --dataset_file ${dataset_file} \
            --file_table_file ${file_table_file} \
            --model_file ${model_url} \
            --out_prefix ${out_prefix} \
            --workspace_name ${workspace_name} \
            --workspace_namespace ${workspace_namespace}
    }

    output {
        File file_report = "pre_import_check.html"
        Array[File]? tables = glob("*_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.2.4.1"
    }
}
