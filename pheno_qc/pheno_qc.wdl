version 1.0

workflow pheno_qc {
    input{
        File data_file
    }

    call run_qc {
        input: data_file = data_file
    }

    output{
        File qc_report = run_qc.qc_report
    }
}

task run_qc {
    input{
        File data_file
    }

    command <<<
        Rscript /usr/local/primed-file-checks/pheno_qc/run_qc.R \
        --data_file ~{data_file} \
        --path_to_rmd /usr/local/primed-file-checks/pheno_qc/
    >>>

    output{
        File qc_report = "qc_report.html"
    }

    runtime{
        docker: "uwgac/primed-file-checks:0.5.0"
    }
}