library(dplyr)
library(readr)

n <- 10 # number of rows in test data

subject <- tibble(
  subject_id = paste0("subject", 1:n), 
  age_at_obs=round(runif(n, 20, 80))
)

cmqt_anthropometry <- tibble(
  subject_id=rep(subject$subject_id),
  age_at_obs=rep(subject$age_at_obs),
  visit=rep(1, n),
  height_1=rnorm(n, 500, 10), # height in cm
  weight_1=rnorm(n, 400, 5), # weight in kg 
  bmi_1=weight_1 / (height_1 / 100)^2, # bmi in km/m^2
  # waist_hip_ratio_1
)

cmqt_lipids <- tibble(
  subject_id=rep(subject$subject_id),
  age_at_obs=rep(subject$age_at_obs),
  visit=rep(1, n),
  triglycerides_1=rnorm(n, 600, 100), # mg/dL
)

# setwd("~/Downloads/primed-file-checks/pheno_qc")
write_tsv(subject, "test_data/subject.tsv")
write_tsv(cmqt_anthropometry, "test_data/cmqt_anthropometry.tsv")
write_tsv(cmqt_lipids, "test_data/cmqt_lipids.tsv")
