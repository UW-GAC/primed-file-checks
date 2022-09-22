library(dplyr)
library(readr)

alleles <- c("A", "C", "G", "T")
chr <- 1:2
n <- round(runif(length(chr), min=100, max=200))
files <- paste0("testdata/gsr_chr", chr, ".tsv")

for (i in 1:length(n)) {
    set.seed(i)
    dat <- tibble(
        chromosome=i,
        position=1:n[i],
        strand=sample(c("+","-"), n[i], replace=TRUE),
        effect_allele=sample(alleles, n[i], replace=TRUE),
        other_allele=sample(alleles, n[i], replace=TRUE),
        effect_allele_freq=runif(n[i]),
        p_value=runif(n[i])
    )
    write_tsv(dat, files[i])
}

files <- tibble(
    chromosome=1:length(n),
    num_vars=n,
    file_type="data",
    file_path=paste0("testdata/", files),
    md5sum=openssl::md5(files)
)

write_tsv(files, "testdata/gsr_file.tsv")


library(tibble)
library(readr)

set.seed(42)
n <- 10

subject <- tibble(
    subject_id = paste0("subject", 1:n),
    consent_code = rep("GRU", n),
    study_nickname = rep("study", n),
    dbgap_submission = c(rep(TRUE, 2), rep(FALSE, n-2)),
    reported_sex = sample(c("F", "M", "X"), n, replace=TRUE)
)

phenotype <- tibble(
    subject_id = rep(subject$subject_id, each=2),
    visit_id = rep(1:2, n),
    height = rep(rnorm(n, 170, 10), each=2),
    weight = rnorm(n*2, 75, 5)
)

sample <- tibble(
    sample_id = paste0("sample", c("1a", 1:n)),
    subject_id = c(subject$subject_id[1], subject$subject_id),
    tissue_source = "blood",
    age_at_sample_collection = round(runif(n+1, 20, 80)),
    date_of_sample_processing = c("2000-01-02", rep("2000-01-01", n))
)

sample_set <- tibble(
    sample_set_id = c(rep("set1", 3), rep("set2", 5)),
    sample_id = c(sample$sample_id[2:4], sample$sample_id[3:7])
)

rand_string <- function(x) {
    paste0(sample(c(letters,0:9), x, replace=TRUE), collapse="")
}

filename <- sapply(1:2, function(x) rand_string(6))
file <- tibble(
    md5sum = sapply(1:4, function(x) rand_string(32)),
    file_path = paste0("gs://fc-8ce226a8-7d00-41b7-a315-5bd2fd521659/", paste0(rep(filename, each=2), rep(c(".vcf.gz", ".vcf.gz.tbi"), length(filename))))
)

write_tsv(subject, "testdata/subject.tsv")
write_tsv(phenotype, "testdata/phenotype.tsv")
write_tsv(sample, "testdata/sample.tsv")
write_tsv(sample_set, "testdata/sample_set.tsv")
write_tsv(file, "testdata/file.tsv")
