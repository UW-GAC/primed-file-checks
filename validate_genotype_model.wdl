version 1.0

import "https://raw.githubusercontent.com/UW-GAC/anvil-util-workflows/main/check_md5.wdl" as md5
import "check_vcf_samples.wdl" as vcf

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

        call select_vcf_files {
            input: validated_table_files = val_tables
        }

        # can only check VCF files once tables are imported since check_vcf_samples reads tables
        if (import_tables && select_vcf_files.files_to_check[0] != "NULL") {
            scatter (pair in zip(zip(select_vcf_files.files_to_check, select_vcf_files.ids_to_check), 
                                 select_vcf_files.datasets_to_check)) {
                call vcf.check_vcf_samples {
                    input: vcf_file = pair.left.left,
                        dataset_id = pair.left.right,
                        dataset_type = pair.right,
                        workspace_name = workspace_name,
                        workspace_namespace = workspace_namespace
                }
            }

            call vcf.summarize_vcf_check {
                input: file = select_vcf_files.files_to_check,
                    vcf_check = check_vcf_samples.vcf_sample_check
            }
        }
    }

    output {
        File validation_report = validate.validation_report
        Array[File]? tables = validate.tables
        String? md5_check_summary = summarize_md5_check.summary
        File? md5_check_details = summarize_md5_check.details
        String? vcf_check_summary = summarize_vcf_check.summary
        File? vcf_check_details = summarize_vcf_check.details
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
        Rscript /usr/local/primed-file-checks/prep_datasets.R \
            --table_files ~{write_map(table_files)} \
            --model_file ~{model_url} \
            --hash_id_nchar ~{hash_id_nchar}
        echo "starting validation"
        Rscript /usr/local/anvil-util-workflows/validate_data_model.R \
            --table_files output_table_files.tsv \
            --model_file ~{model_url} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace} \
            --stop_on_fail --use_existing_tables \
            --hash_id_nchar ~{hash_id_nchar}
        if [[ "~{import_tables}" == "true" ]]
        then
          echo "starting import"
          Rscript /usr/local/anvil-util-workflows/data_table_import.R \
            --table_files output_tables.tsv \
            --model_file ~{model_url} ~{true="--overwrite" false="" overwrite} \
            --workspace_name ~{workspace_name} \
            --workspace_namespace ~{workspace_namespace}
        fi
    >>>

    output {
        File validation_report = "data_model_validation.html"
        Array[File]? tables = glob("output_*_table.tsv")
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
        R << RSCRIPT
            tables <- readLines('~{write_lines(validated_table_files)}')
            names(tables) <- sub('^output_', '', sub('_table.tsv', '', basename(tables)))
            md5_tbls <- c('array_file', 'imputation_file', 'sequencing_file', 'simulation_file')
            files <- list(); md5 <- list();
            for (t in intersect(md5_tbls, names(tables))) {
                dat <- readr::read_tsv(tables[t])
                files[[t]] <- dat[['file_path']]
                md5[[t]] <- dat[['md5sum']]
            }
            if ('sequencing_sample' %in% names(tables)) {
                dat <- readr::read_tsv(tables[['sequencing_sample']])
                for (type in c('cram', 'gvcf', 'vcf')) {
                    if (paste0(type, '_file_path') %in% names(dat)) {
                        files[[type]] <- dat[[paste0(type, '_file_path')]]
                        md5[[type]] <- dat[[paste0(type, '_md5sum')]]
                    }
                }
            }
            if (length(unlist(files)) > 0) {
                writeLines(unlist(files), 'file.txt')
                writeLines(unlist(md5), 'md5sum.txt')
            } else {
                writeLines('NULL', 'file.txt')
                writeLines('NULL', 'md5sum.txt')
            }
        RSCRIPT
    >>>

    output {
        Array[String] files_to_check = read_lines("file.txt")
        Array[String] md5sum_to_check = read_lines("md5sum.txt")
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.17.0"
    }
}


task select_vcf_files {    
    input {
        Array[File] validated_table_files
    }

    command <<<
        Rscript -e "\
        tables <- readLines('~{write_lines(validated_table_files)}'); \
        names(tables) <- sub('^output_', '', sub('_table.tsv', '', basename(tables))); \
        dataset_types <- c('array', 'imputation', 'sequencing', 'simulation'); \
        dataset_tables <- paste0(dataset_types, '_file'); \
        tables <- tables[names(tables) %in% dataset_tables]; \
        files <- list(); ids <- list(); datasets <- list(); \
        for (t in names(tables)) { \
          dat <- readr::read_tsv(tables[t]); \
          dat <- dplyr::filter(dat, file_type == 'VCF'); \
          files[[t]] <- dat[['file_path']]; \
          ids[[t]] <- dat[[sub('_file', '_dataset_id', t)]]; \
          datasets[[t]] <- rep(sub('_file', '', t), nrow(dat)); \
        }; \
        if (length(unlist(files)) > 0) { \
          writeLines(unlist(files), 'file.txt'); \
          writeLines(unlist(ids), 'id.txt'); \
          writeLines(unlist(datasets), 'dataset.txt'); \
        } else { \
          writeLines('NULL', 'file.txt'); \
          writeLines('NULL', 'id.txt'); \
          writeLines('NULL', 'dataset.txt'); \
        } \
        "
    >>>

    output {
        Array[String] files_to_check = read_lines("file.txt")
        Array[String] ids_to_check = read_lines("id.txt")
        Array[String] datasets_to_check = read_lines("dataset.txt")
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.17.0"
    }
}
