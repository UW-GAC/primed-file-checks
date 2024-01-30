version 1.0

workflow pheno_qc {
    input{
        File data_file
        String path_to_rmd
    }

    call run_qc {
        input: data_file = data_file,
               path_to_rmd = path_to_rmd
    }

    output{
        File qc_report = run_qc.qc_report
    }
}

task run_qc {
    input{
        File data_file
        String path_to_rmd
    }

    command <<<
        Rscript /usr/local/primed-file-checks/pheno_qc/run_qc.R \
        --data_file ~{data_file} \
        --path_to_rmd ~{path_to_rmd}
    >>>

    output{
        File qc_report = "~{path_to_rmd}/template_main_qc.html"
    }

    runtime{
        docker: "uwgac/primed-file-checks:pheno_qc"
    }
}