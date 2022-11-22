# primed-file-checks

Data uploaded to PRIMED workspaces should conform to the [PRIMED data model](https://github.com/UW-GAC/primed_data_models). An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies.

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

The Dockerfile creates a docker image containing the AnvilDataModels R package and R script to generate the report. It contains the R scripts in this repository and is available on Docker Hub as
[uwgac/primed-file-checks](https://hub.docker.com/r/uwgac/primed-file-checks).


## genotype_report

This workflow is a data model report specific to the PRIMED genotype data model. It checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

A dataset table is supplied in long form as key/value pairs ([example](testdata/dataset.tsv)) rather than wide form. The dataset_type parameter defines whether the dataset will be added to the array_dataset, imputation_dataset, or sequencing_dataset table. A unique `<type>_dataset_id` is added to both the dataset table and the file table to link the dataset and the data files.

This workflow returns, in addition to reports, TSV files with the '<type>_dataset' and '<type>_file' tables with the `<type>_dataset_id` added. The user can then use functions from the AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package to import these tables to an AnVIL workspace.

The user must specify the following inputs:

input | description
--- | ---
subject_file | Google bucket path to a TSV file with contents of the 'subject' table.
sample_file | Google bucket path to a TSV file with contents of the 'sample' table.
sample_set_file | Google bucket path to a TSV file with contents of the 'sample_set' table.
dataset_type | The type of dataset; one of 'array', 'imputation', or 'sequencing'.
dataset_file | Google bucket path to a TSV file with two columns: `field` and `value`, where the fields correspond to fields in the <type>_dataset table. 
file_table_file | Google bucket path to a TSV file with contents of the '<type>_file' table.
model_url | A URL providing the path to the data model in JSON format.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
tables | A file array with the tables after adding auto-generated columns. These tables can be imported into an AnVIL workspace as data tables. This output is not generated if no additional columns are specified in the data model.
pass_checks | a boolean value where 'true' means the set of tables fulfilled the minimum requirements of the data model (all required tables/columns present)


## gsr_report

This workflow is a data model report specific to the PRIMED Genomic Summary Results (GSR) data model. The analysis table is supplied in long form as key/value pairs ([example](testdata/gsr_analysis_table.tsv)) rather than wide form. A unique `analysis_id` is added to both the analysis table and the file table to link the analysis and the data files.

This workflow returns, in addition to reports, TSV files with the 'analysis' and 'file' tables with the `analysis_id` added. The user can then use functions from the AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package to import these tables to an AnVIL workspace.

The user must specify the following inputs:

input | description
--- | ---
analysis_file | Google bucket path to a TSV file with two columns: `field` and `value`, where the fields correspond to fields in the analysis table of the PRIMED GSR data model. 
file_table_file | Google bucket path to a TSV file with contents of the 'file' table.
model_url | A URL providing the path to the data model in JSON format.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
tables | A file array with the analysis and file tables after adding the `analysis_id`. These tables can be imported into an AnVIL workspace as data tables.
pass_checks | a boolean value where 'true' means the set of tables fulfilled the minimum requirements of the data model (all required tables/columns present)


## gsr_data_report

This workflow is a data dictionary report specific to the PRIMED Genomic Summary Results (GSR) data model. It includes checking conditional fields depending on values in the analysis table.

The user must specify the following inputs:

input | description
--- | ---
data_file | Google bucket path to a TSV data file.
dd_url | A URL providing the path to the data dictionary in JSON format.
analysis_file | Google bucket path to the TSV file containing the analysis data table, output by gsr_report.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
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
