library(dplyr)

alleles <- c("A", "C", "G", "T")
chr <- 1:2
n <- round(runif(length(chr), min=100, max=200))
files <- paste0("gsr_chr", chr, ".tsv")

for (i in 1:length(n)) {
    set.seed(i)
    dat <- tibble(
        chr=i,
        num_vars=n[i],
        position=1:n[i],
        strand=sample(c("+","-"), n[i], replace=TRUE),
        effect_allele=sample(alleles, n[i], replace=TRUE),
        other_allele=sample(alleles, n[i], replace=TRUE),
        effect_allele_freq=runif(n[i]),
        p_value=runif(n[i])
    )
    readr::write_tsv(dat, files[i])
}

files <- tibble(
    chromosome=1:length(n),
    num_vars=n,
    file_type="data",
    file_path=paste0("testdata/", files),
    md5sum=openssl::md5(files)
)

readr::write_tsv(files, "gsr_file.tsv")
