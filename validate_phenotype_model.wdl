version 1.0

import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/check_md5.wdl" as md5
import "pheno_qc/pheno_qc.wdl" as qc

workflow validate_phenotype_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Int? hash_id_nchar
    }

    call validate {
        input: table_files = table_files,
               model_url = model_url,
               hash_id_nchar = hash_id_nchar,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    # need this because validate_data_model.tables is optional but input to select_md5_files is required
    Array[File] val_tables = select_first([validate.tables, ""])
    String harmonized_table = select_first([validate.harmonized_table, ""])

    if (defined(validate.tables)) {
        call select_md5_files {
            input: validated_table_files = val_tables
        }

        if (select_md5_files.files_to_check[0] != "NULL") {
            scatter (pair in zip(select_md5_files.files_to_check, select_md5_files.md5sum_to_check)) {
                call md5.md5check {
                    input: file = pair.left,
                        md5sum = pair.right
                }
            }

            call md5.summarize_md5_check {
                input: file = select_md5_files.files_to_check,
                    md5_check = md5check.md5_check
            }
        }

        call qc.run_qc {
            input: data_file = harmonized_table,
                workspace_name = workspace_name
        }

        if (import_tables) {
            call add_qc_report_to_table {
                input: harmonized_table = harmonized_table,
                    qc_report_path = run_qc.qc_report,
                    workspace_name = workspace_name,
                    workspace_namespace = workspace_namespace
            }
        }
    }

    output {
        File validation_report = validate.validation_report
        Array[File]? tables = validate.tables
        String? md5_check_summary = summarize_md5_check.summary
        File? md5_check_details = summarize_md5_check.details
        File? qc_report = run_qc.qc_report
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task validate {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite
        Boolean import_tables
        Int hash_id_nchar = 16
    }

    command <<<
        set -e
        echo "starting prep"
        Rscript /usr/local/primed-file-checks/prep_phenotypes.R \
            --table_files ~{write_map(table_files)} \
            --model_file ~{model_url} \
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
        if [[ "~{import_tables}" == "true" ]]
        then
          echo "starting import"
          Rscript /usr/local/primed-file-checks/select_import_phenotypes.R \
            --table_files output_tables.tsv
          Rscript /usr/local/anvil-util-workflows/data_table_import.R \
            --table_files output_table_files_import.tsv \
            --model_file ~{model_url} ~{true="--overwrite" false="" overwrite} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        fi
    >>>

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("output_*_table.tsv")
        File? harmonized_table = "output_phenotype_harmonized_table.tsv"
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.5.1"
    }
}


task select_md5_files {
    input {
        Array[File] validated_table_files
    }

    command <<<
        Rscript -e "\
        tables <- readLines('~{write_lines(validated_table_files)}'); \
        names(tables) <- sub('^output_', '', sub('_table.tsv', '', basename(tables))); \
        md5_tbls <- c('phenotype_harmonized', 'phenotype_unharmonized'); \
        tables <- tables[names(tables) %in% md5_tbls]; \
        files <- list(); md5 <- list();
        for (t in names(tables)) { \
          dat <- readr::read_tsv(tables[t]); \
          files[[t]] <- dat[['file_path']]; \
          md5[[t]] <- dat[['md5sum']]; \
        }; \
        if (length(files) > 0) { \
          writeLines(unlist(files), 'file.txt'); \
          writeLines(unlist(md5), 'md5sum.txt'); \
        } else { \
          writeLines('NULL', 'file.txt'); \
          writeLines('NULL', 'md5sum.txt'); \
        } \
        "
    >>>

    output {
        Array[String] files_to_check = read_lines("file.txt")
        Array[String] md5sum_to_check = read_lines("md5sum.txt")
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.17.0"
    }
}


task add_qc_report_to_table {
    input {
        File harmonized_table
        String qc_report_path
        String workspace_name
        String workspace_namespace
    }

    command <<<
        Rscript -e "\
        phen <- readr::read_tsv('~{harmonized_table}'); \
        phen <- dplyr::select(phen, phenotype_harmonized_id); \
        phen <- dplyr::mutate(phen, qc_report='~{qc_report_path}'); \
        AnVIL::avtable_import(phen, namespace='~{workspace_namespace}', name='~{workspace_name}'); \
        "
    >>>

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.17.0"
    }
}
