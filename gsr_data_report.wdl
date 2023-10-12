version 1.0

workflow gsr_data_report {
    input {
        File data_file
        String dd_url
        File analysis_file
    }

    call validate_data {
        input: data_file = data_file,
               dd_url = dd_url,
               analysis_file = analysis_file
    }

    output {
        File validation_report = validate_data.validation_report
        Boolean pass_checks = validate_data.pass_checks
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task validate_data {
    input {
        File data_file
        String dd_url
        File analysis_file
    }

    command <<<
        Rscript /usr/local/primed-file-checks/gsr_data_report.R \
            --data_file ~{data_file} \
            --dd_file ~{dd_url} \
            --analysis_file ~{analysis_file} \
            --stop_on_fail
    >>>

    output {
        File validation_report = "data_dictionary_validation.html"
        Boolean pass_checks = read_boolean("pass.txt")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.4.5"
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
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.17.0"
    }
}
