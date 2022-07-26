version 1.0

workflow genotype_report {
    input {
        File subject_file
        File sample_file
        File sample_set_file
        String dataset_type
        File dataset_file
        File file_table_file
        String model_url
        String out_prefix
    }

    call results {
        input: subject_file = subject_file,
               sample_file = sample_file,
               sample_set_file = sample_set_file,
               dataset_type = dataset_type,
               dataset_file = dataset_file,
               file_table_file = file_table_file,
               model_url = model_url,
               out_prefix = out_prefix
    }

    output {
        File file_report = results.file_report
        Boolean pass_checks = results.pass_checks
        Array[File]? tables = results.tables
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task results{
    input {
        File subject_file
        File sample_file
        File sample_set_file
        String dataset_type
        File dataset_file
        File file_table_file
        String model_url
        String out_prefix
    }

    command {
        Rscript /usr/local/primed-file-checks/genotype_report.R \
            --subject_file ${subject_file} \
            --sample_file ${sample_file} \
            --sample_set_file ${sample_set_file} \
            --dataset_type ${dataset_type} \
            --dataset_file ${dataset_file} \
            --file_table_file ${file_table_file} \
            --model_file ${model_url} \
            --out_prefix ${out_prefix}
    }

    output {
        File file_report = "${out_prefix}.html"
        Boolean pass_checks = read_boolean("pass.txt")
        Array[File]? tables = glob("*_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.1.0"
    }
}
