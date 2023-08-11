version 1.0

workflow gsr_data_report {
    input {
        File data_file
        String dd_url
        String analysis_id
        String workspace_name
        String workspace_namespace
    }

    call validate {
        input: data_file = data_file,
               dd_url = dd_url,
               analysis_id = analysis_id,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace
    }

    output {
        File validation_report = validate.validation_report
        Boolean pass_checks = validate.pass_checks
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task validate {
    input {
        File data_file
        String dd_url
        String analysis_id
        String workspace_name
        String workspace_namespace
    }

    command <<<
        Rscript /usr/local/primed-file-checks/gsr_data_report.R \
            --data_file ~{data_file} \
            --dd_file ~{dd_url} \
            --analysis_id ~{analysis_id} \
            --stop_on_fail \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
    >>>

    output {
        File validation_report = "data_dictionary_validation.txt"
        Boolean pass_checks = read_boolean("pass.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.2"
    }
}


task summarize_data_check {
    input {
        Array[String] file
        Array[Boolean] data_check
        Array[File] validation_report
    }

    command <<<
        Rscript -e "\
        files <- readLines('~{write_lines(file)}'); \
        checks <- readLines('~{write_lines(data_check)}'); \
        reports <- readLines('~{write_lines(validation_report)}'); \
        library(dplyr); \
        dat <- tibble(file_path=files, data_check=checks, validation_report=reports); \
        dat <- mutate(dat, data_check = ifelse(data_check == 'true', 'PASS', 'FAIL')); \
        readr::write_tsv(dat, 'details.txt'); \
        ct <- mutate(count(dat, data_check), x=paste(n, data_check)); \
        writeLines(paste(ct[['x']], collapse=', '), 'summary.txt'); \
        "
    >>>
    
    output {
        String summary = read_string("summary.txt")
        File details = "details.txt"
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
