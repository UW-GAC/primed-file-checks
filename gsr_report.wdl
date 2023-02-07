version 1.0

workflow gsr_report {
    input {
        File analysis_file
        File file_table_file
        String model_url
        String out_prefix = "report"
    }

    call results {
        input: analysis_file = analysis_file,
               file_table_file = file_table_file,
               model_url = model_url,
               out_prefix = out_prefix
    }

    output {
        File file_report = results.file_report
        Array[File] tables = results.tables
        Boolean pass_checks = results.pass_checks
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task results{
    input {
        File analysis_file
        File file_table_file
        String model_url
        String out_prefix
    }

    command {
        Rscript /usr/local/primed-file-checks/gsr_report.R \
            --analysis_file ${analysis_file} \
            --file_table_file ${file_table_file} \
            --model_file ${model_url} \
            --out_prefix ${out_prefix}
    }

    output {
        File file_report = "${out_prefix}.html"
        Array[File] tables = glob("*_table.tsv")
        Boolean pass_checks = read_boolean("pass.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.2.4"
    }
}
