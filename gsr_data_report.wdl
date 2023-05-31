version 1.0

workflow gsr_data_report {
    input {
        File data_file
        String dd_url
        String analysis_id
        String workspace_name
        String workspace_namespace
    }

    call results {
        input: data_file = data_file,
               dd_url = dd_url,
               analysis_id = analysis_id,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace
    }

    output {
        File validation_report = results.validation_report
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
        String analysis_id
        String workspace_name
        String workspace_namespace
    }

    command {
        Rscript /usr/local/primed-file-checks/gsr_data_report.R \
            --data_file ${data_file} \
            --dd_file ${dd_url} \
            --analysis_id ${analysis_id} \
            --workspace_name ${workspace_name} \
            --workspace_namespace ${workspace_namespace}
    }

    output {
        File validation_report = "data_dictionary_validation.txt"
        Boolean pass_checks = read_boolean("pass.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.1"
    }
}
