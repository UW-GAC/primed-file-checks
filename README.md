# primed-file-checks

Data uploaded to PRIMED workspaces should conform to the [PRIMED data model](https://github.com/UW-GAC/primed_data_models). An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies.

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

The Dockerfile creates a docker image containing the AnvilDataModels R package and R script to generate the report. It contains the R scripts in this repository and is available on Docker Hub as
[uwgac/primed-file-checks](https://hub.docker.com/r/uwgac/primed-file-checks).


## validate_genotype_model

Workflow to validate TSV files against the PRIMED genotype data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package. An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies. 

If the data model specifies that any columns be auto-generated from other columns, the workflow generates TSV files with updated tables before running checks.

Each dataset table is supplied in long form as key/value pairs ([example](testdata/dataset.tsv)) rather than wide form. A unique `<type>_dataset_id` is added to both the dataset table and the file table to link the dataset and the data files.

This workflow checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

If miminal checks are passed and `import_tables` is set to `true`, the workflow will then import the files as data tables in an AnVIL workspace. If checks are not passed, the workflow will fail and the user should review the file "data_model_validation.html" in the workflow output directory.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in JSON format.
import_tables | A boolean indicating whether tables should be imported to a workspace after validation.
overwrite | A boolean indicating whether existing rows in the data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | An HTML file with validation results
tables | A file array with the tables after adding auto-generated columns. This output is not generated if no additional columns are specified in the data model.


## validate_gsr_model

Workflow to validate TSV files against the PRIMED Genomic Summary Results (GSR) data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package. An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies. 

If the data model specifies that any columns be auto-generated from other columns, the workflow generates TSV files with updated tables before running checks.

The analysis table is supplied in long form as key/value pairs ([example](testdata/gsr_analysis_table.tsv)) rather than wide form. A unique `analysis_id` is added to both the analysis table and the file table to link the analysis and the data files.

This workflow checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

If miminal checks are passed and `import_tables` is set to `true`, the workflow will then import the files as data tables in an AnVIL workspace. If checks are not passed, the workflow will fail and the user should review the file "data_model_validation.html" in the workflow output directory.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in JSON format.
import_tables | A boolean indicating whether tables should be imported to a workspace after validation.
overwrite | A boolean indicating whether existing rows in the data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
validation_report | An HTML file with validation results
tables | A file array with the tables after adding auto-generated columns. This output is not generated if no additional columns are specified in the data model.


## gsr_data_report

This workflow is a data dictionary report specific to the PRIMED Genomic Summary Results (GSR) data model. It includes checking conditional fields depending on values in the analysis table.

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
mem_gb | (optional, default 10 GB) RAM required. If the job fails due to lack of memory, try setting this to a larger value.


The workflow returns the following outputs:

output | description
--- | ---
vcf_sample_check | "PASS" or "FAIL" indicating whether the VCF sample ids match the sample_set in the workspace data tables
