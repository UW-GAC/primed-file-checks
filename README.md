# primed-file-checks

Workflows to check TSV files against a data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package.

## Overview

Data uploaded to PRIMED workspaces should conform to the [PRIMED data model](https://github.com/UW-GAC/primed_data_models). An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies.

### Docker

The Dockerfile creates a docker image containing the AnvilDataModels R package and R script to generate the report. The
image is available on Docker Hub as
[uwgac/anvildatamodels](https://hub.docker.com/r/uwgac/anvildatamodels).

### WDL

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

## Workflows

### data_model_report

This workflow checks whether expected tables (both required and optional) are included. For each table, it checks column names, data types, and primary keys. Finally, it checks foreign keys (cross-references across tables). Results of all checks are displayed in an HTML file.

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in TSV format.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
pass_checks | a boolean value where 'true' means the set of tables fulfilled the minimum requirements of the data model (all required tables/columns present)


### gsr_report

This workflow performs the same checks as the data_model_report workflow, but first performs some GSR-specific manipulations to the input. The analysis table is supplied in long form as key/value pairs ([example](testdata/gsr_analysis_table.tsv)) rather than wide form. A unique `primed_gwas_id` is added to both the analysis table and the file table to link the analysis and the data files.

This workflow returns, in addition to reports, TSV files with the 'analysis' and 'file' tables with the `primed_gwas_id` added. The user can then use functions from the AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package to import these tables to an AnVIL workspace.

The user must specify the following inputs:

input | description
--- | ---
analysis_file | Google bucket path to a TSV file with two columns: `field` and `value`, where the fields correspond to fields in the analysis table of the PRIMED GSR data model. 
file_table_file | Google bucket path to a TSV file with contents of the 'file' table.
model_url | A URL providing the path to the data model in TSV format.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
table | A file array with the analysis and file tables after adding the `primed_gwas_id`. These tables can be imported into an AnVIL workspace as data tables.
pass_checks | a boolean value where 'true' means the set of tables fulfilled the minimum requirements of the data model (all required tables/columns present)


### data_dictionary_report

This workflow checks TSV-formatted data files against a data dictionary (DD). The DD should be specified in the same format as a data model. 

The user must specify the following inputs:

input | description
--- | ---
data_file | Google bucket path to a TSV data file.
dd_url | A URL providing the path to the data dictionary in TSV format.
out_prefix | A prefix for the resulting HTML report.

The workflow returns the following outputs:

output | description
--- | ---
file_report | An HTML file with check results
pass_checks | a boolean value where 'true' means the data file fulfilled the minimum requirements of the data dictionary (all required columns present)
