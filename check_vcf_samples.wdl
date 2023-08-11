version 1.0

workflow check_vcf_samples {
    input {
        File vcf_file
        String dataset_id
        String dataset_type
        String workspace_name
        String workspace_namespace
        Int? disk_gb
    }

    call vcf_samples {
        input: vcf_file = vcf_file,
               disk_gb = disk_gb
    }

    call compare_sample_sets {
        input: sample_file = vcf_samples.sample_file,
               dataset_id = dataset_id,
               dataset_type = dataset_type,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace
    }

    output {
        String vcf_sample_check = compare_sample_sets.check_status
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
     }
}

task vcf_samples {
    input {
        File vcf_file
        Int disk_gb = 10
    }

    command {
        bcftools query --list-samples ${vcf_file} > samples.txt
    }

    output {
        File sample_file = "samples.txt"
    }

    runtime {
        docker: "xbrianh/xsamtools:v0.5.2"
        disks: "local-disk ${disk_gb} SSD"
    }
}

task compare_sample_sets {
    input {
        File sample_file
        String dataset_id
        String dataset_type
        String workspace_name
        String workspace_namespace
    }

    command <<<
        Rscript -e "\
        dataset_id <- '~{dataset_id}'; \
        dataset_type <- '~{dataset_type}'; \
        workspace_name <- '~{workspace_name}'; \
        workspace_namespace <- '~{workspace_namespace}'; \
        stopifnot(dataset_type %in% c('array', 'imputation', 'sequencing')); \
        dataset_table <- AnVIL::avtable(paste0(dataset_type, '_dataset'), name=workspace_name, namespace=workspace_namespace); \
        sample_set_id <- dataset_table[['sample_set_id']][dataset_table[[paste0(dataset_type, '_dataset_id')]] == dataset_id]; \
        sample_set <- AnVIL::avtable('sample_set', name=workspace_name, namespace=workspace_namespace); \
        samples <- sample_set[['samples.items']][sample_set[['sample_set_id']] == sample_set_id][[1]][['entityName']]; \
        writeLines(samples, 'workspace_samples.txt'); \
        vcf_samples <- readLines('~{sample_file}'); \
        if (setequal(samples, vcf_samples)) status <- 'PASS' else status <- 'FAIL'; \
        cat(status, file='status.txt'); \
        if (status == 'FAIL') stop('Samples do not match; compare vcf_samples.txt and workspace_samples.txt') \
        "
    >>>

    output {
        String check_status = read_string("status.txt")
        File workspace_samples = "workspace_samples.txt"
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}


task summarize_vcf_check {
    input {
        Array[String] file
        Array[String] vcf_check
    }

    command <<<
        Rscript -e "\
        files <- readLines('~{write_lines(file)}'); \
        checks <- readLines('~{write_lines(vcf_check)}'); \
        library(dplyr); \
        dat <- tibble(file_path=files, vcf_check=checks); \
        readr::write_tsv(dat, 'details.txt'); \
        ct <- mutate(count(dat, vcf_check), x=paste(n, vcf_check)); \
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
