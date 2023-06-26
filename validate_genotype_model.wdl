version 1.0

import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/check_md5.wdl" as md5

workflow validate_genotype_model {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
        Int? hash_id_nchar
    }

    call results {
        input: table_files = table_files,
               model_url = model_url,
               hash_id_nchar = hash_id_nchar,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    # need this because validate_data_model.tables is optional but input to select_md5_files is required
    Array[File] val_tables = select_first([results.tables, ""])

    if (defined(results.tables)) {
        call select_md5_files {
            input: validated_table_files = val_tables
        }

        if (select_md5_files.files_to_check[0] != "NULL") {
            scatter (pair in zip(select_md5_files.files_to_check, select_md5_files.md5sum_to_check)) {
                call md5.check_md5 {
                    input: file = pair.left,
                        md5sum = pair.right
                }
            }

            call md5.summarize_md5_check {
                input: file = select_md5_files.files_to_check,
                    md5_check = check_md5.md5_check
            }
        }
    }

    output {
        File validation_report = results.validation_report
        Array[File]? tables = results.tables
        String? md5_check_summary = summarize_md5_check.summary
        File? md5_check_details = summarize_md5_check.details
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task results {
    input {
        Map[String, File] table_files
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite
        Boolean import_tables
        Int hash_id_nchar = 16
    }

    command {
        Rscript /usr/local/primed-file-checks/prep_datasets.R \
            --table_files ${write_map(table_files)} \
            --model_file ${model_url} \
            --hash_id_nchar ${hash_id_nchar}
        Rscript /usr/local/anvil-util-workflows/validate_data_model.R \
            --table_files output_table_files.tsv \
            --model_file ${model_url} \
            --workspace_name ${workspace_name} \
            --workspace_namespace ${workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ${hash_id_nchar}
        if [[ "~{import_tables}" == "true" ]]
        then
          Rscript /usr/local/anvil-util-workflows/data_table_import.R \
            --table_files output_tables.tsv \
            --model_file ${model_url} ${true="--overwrite" false="" overwrite} \
            --workspace_name ${workspace_name} \
            --workspace_namespace ${workspace_namespace}
        fi
    }

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("output_*_table.tsv")
    }

    runtime {
        docker: "uwgac/primed-file-checks:0.3.2"
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
        md5_tbls <- c('array_file', 'imputation_file', 'sequencing_file', 'simulation_file'); \
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
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
