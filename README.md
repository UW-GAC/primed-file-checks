# primed-file-checks

Data uploaded to PRIMED workspaces should conform to the [PRIMED data model](https://github.com/UW-GAC/primed_data_models). An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies.

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

The Dockerfile creates a docker image containing the AnvilDataModels R package and R script to generate the report. It contains the R scripts in this repository and is available on Docker Hub as
[uwgac/primed-file-checks](https://hub.docker.com/r/uwgac/primed-file-checks).


## validate_phenotype_model

Workflow to validate TSV files against the PRIMED phenotype data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package. An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies. 

If the data model specifies that any columns be auto-generated from other columns, the workflow generates TSV files with updated tables before running checks.

Phenotype tables in TSV form are listed in either a “phenotype_harmonized” table (for domain tables where adherence to the data model is verified by the workflow), and/or a “phenotype_unharmonized” table (for tables where only the column “subject_id” is required).

Phenotype domain tables are supplied in long form with each row as one time per subject rather than wide form. The set of columns that form a unique observation is indicated in the “Primary key” column in the data model.

This workflow checks whether the subject table, phenotype_harmonized and phenotype_unharmonized tables, and domain tables conform to the data model. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file. For unharmonized phenotype tables, the only check performed is whether the “subject_id” column exists and that all values appear in the subject table.

If any tables in the data model are not included in the "table_files" input but are already present in the workspace, the workflow will read them from the workspace for cross-checks with supplied tables.

If miminal checks are passed and `import_tables` is set to `true`, the workflow will then import the files as data tables in an AnVIL workspace. If checks are not passed, the workflow will fail and the user should review the file "data_model_validation.html" in the workflow output directory.

If validation is successful, the workflow will check the md5sums provided for each phenotype file against the value in google cloud storage. For each file, the workflow will return 'PASS' if the check was successful or 'UNVERIFIED' if the file was found but does not have an md5 value in its metadata. The workflow will fail if the md5sums do not match or if the file is not found. Review the log file for check details including the two md5 values compared.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in JSON format.
hash_id_nchar | Number of characters in auto-generated columns (default 16)
import_tables | A boolean indicating whether tables should be imported to a workspace after validation.
overwrite | A boolean indicating whether existing rows in the data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | An HTML file with validation results
tables | A file array with the tables after adding auto-generated columns. This output is not generated if no additional columns are specified in the data model.
md5_check_summary | A string describing the check results, e.g. "10 PASS; 1 UNVERIFIED"
md5_check_details | A TSV file with two columns: file_path of the file in cloud storage and md5_check with the check result.


## validate_genotype_model

Workflow to validate TSV files against the PRIMED genotype data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package. An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies. 

If the data model specifies that any columns be auto-generated from other columns, the workflow generates TSV files with updated tables before running checks.

Each dataset table is supplied in long form as key/value pairs ([example](testdata/dataset.tsv)) rather than wide form. A unique `<type>_dataset_id` is added to both the dataset table and the file table to link the dataset and the data files.

This workflow checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

If any tables in the data model are not included in the "table_files" input but are already present in the workspace, the workflow will read them from the workspace for cross-checks with supplied tables.

If miminal checks are passed and `import_tables` is set to `true`, the workflow will then import the files as data tables in an AnVIL workspace. If checks are not passed, the workflow will fail and the user should review the file "data_model_validation.html" in the workflow output directory.

If validation is successful, the workflow will check the md5sums provided for each dataset file against the value in google cloud storage. For each file, the workflow will return 'PASS' if the check was successful or 'UNVERIFIED' if the file was found but does not have an md5 value in its metadata. The workflow will fail if the md5sums do not match or if the file is not found. Review the log file for check details including the two md5 values compared.

If validation and import are successful and the dataset_file table contains files with type "VCF", check_vcf_samples (see below) is run on all VCF files.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in JSON format.
hash_id_nchar | Number of characters in auto-generated columns (default 16)
import_tables | A boolean indicating whether tables should be imported to a workspace after validation.
overwrite | A boolean indicating whether existing rows in the data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | An HTML file with validation results
tables | A file array with the tables after adding auto-generated columns. This output is not generated if no additional columns are specified in the data model.
md5_check_summary | A string describing the check results, e.g. "10 PASS; 1 UNVERIFIED"
md5_check_details | A TSV file with two columns: file_path of the file in cloud storage and md5_check with the check result.
vcf_check_summary | A string describing the check results, e.g. "5 PASS"
vcf_check_details | A TSV file with two columns: file_path of the file in cloud storage and vcf_check with the check result.


## validate_gsr_model

Workflow to validate TSV files against the PRIMED Genomic Summary Results (GSR) data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package. An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies. 

If the data model specifies that any columns be auto-generated from other columns, the workflow generates TSV files with updated tables before running checks.

The analysis table is supplied in long form as key/value pairs ([example](testdata/gsr_analysis_table.tsv)) rather than wide form. A unique `analysis_id` is added to both the analysis table and the file table to link the analysis and the data files.

This workflow checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

If miminal checks are passed and `import_tables` is set to `true`, the workflow will then import the files as data tables in an AnVIL workspace. If checks are not passed, the workflow will fail and the user should review the file "data_model_validation.html" in the workflow output directory.

If validation is successful, the workflow will check the md5sums provided for each dataset file against the value in google cloud storage. For each file, the workflow will return 'PASS' if the check was successful or 'UNVERIFIED' if the file was found but does not have an md5 value in its metadata. The workflow will fail if the md5sums do not match or if the file is not found. Review the log file for check details including the two md5 values compared.

If validation is successful, gsr_data_report (see below) is run on all data files.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in JSON format.
hash_id_nchar | Number of characters in auto-generated columns (default 16)
import_tables | A boolean indicating whether tables should be imported to a workspace after validation.
overwrite | A boolean indicating whether existing rows in the data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | An HTML file with validation results
tables | A file array with the tables after adding auto-generated columns. This output is not generated if no additional columns are specified in the data model.
md5_check_summary | A string describing the check results, e.g. "10 PASS; 1 UNVERIFIED"
md5_check_details | A TSV file with two columns: file_path of the file in cloud storage and md5_check with the check result.
data_report_summary | A string describing the check results
data_report_details | A TSV file with two columns: file_path of the file in cloud storage validation_report with the path to a text file with validation details


## gsr_data_report

This workflow validates a GSR data file against the "gsr_files_dd" table in the PRIMED Genomic Summary Results (GSR) data model. It includes checking conditional fields depending on values in the analysis table.

The user must specify the following inputs:

input | description
--- | ---
data_file | Google bucket path to a TSV data file.
dd_url | A URL providing the path to the data dictionary in JSON format.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | A text file with validation results
pass_checks | a boolean value where 'true' means the data file fulfilled the minimum requirements of the data dictionary (all required columns present)


## check_vcf_samples

This workflow checks that the samples in the header of a VCF file match the sample ids in the data model (dataset_id -> sample_set_id -> sample_id).

The user must specify the following inputs:

input | description
--- | ---
vcf_file | Google bucket path to a VCF file
dataset_id | The dataset_id associated with the vcf_file
dataset_type | The type of dataset the file belongs to (array, inmputation, or sequencing)
workspace_name | A string with the workpsace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workpsace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"


The workflow returns the following outputs:

output | description
--- | ---
vcf_sample_check | "PASS" or "FAIL" indicating whether the VCF sample ids match the sample_set in the workspace data tables
