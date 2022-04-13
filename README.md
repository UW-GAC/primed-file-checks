# primed-file-checks

Workflow to check TSV files against a data model using the [AnvilDataModels](https://github.com/UW-GAC/AnvilDataModels) package.

## Overview

Data uploaded to PRIMED workspaces should conform to the [PRIMED data model](https://github.com/UW-GAC/primed_data_models). An uploader will prepare files in tab separated values (TSV) format, with one file for each data table in the model, and upload them to an AnVIL workspace. This workflow will compare those files to the data model, and generate an HTML report describing any inconsistencies.

## Docker

The Dockerfile creates a docker image containing the AnvilDataModels R package and R script to generate the report. The
image is available on Docker Hub as
[uwgac/anvildatamodels](https://hub.docker.com/r/uwgac/anvildatamodels).

## WDL

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

### Submitting a job

The user must specify the following inputs:

input | description
--- | ---
table_files | This input is of type Map[String, File], which consists of key:value pairs. Keys are table names, which should correspond to names in the data model, and values are Google bucket paths to TSV files for each table.
model_url | A URL providing the path to the data model in TSV format.
out_prefix | A prefix for the resulting HTML report.
