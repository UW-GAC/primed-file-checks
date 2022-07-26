version 1.0

workflow data_dictionary_report {
    input {
        File data_file
        String dd_url
        String out_prefix
    }

    call results {
        input: data_file = data_file,
               dd_url = dd_url,
               out_prefix = out_prefix
    }

    output {
        File file_report = results.file_report
        Boolean pass_checks = results.pass_checks
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task results{
    input {
        File data_file
        String dd_url
        String out_prefix
    }

    command {
        Rscript /usr/local/primed-file-checks/data_dictionary_report.R \
            --data_file ${data_file} \
            --dd_file ${dd_url} \
            --out_prefix ${out_prefix}
    }

    output {
        File file_report = "${out_prefix}.txt"
        Boolean pass_checks = read_boolean("pass.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.1.0"
    }
}
