FROM us.gcr.io/anvil-gcr-public/anvil-rstudio-bioconductor-devel:3.15.0
    
RUN Rscript -e 'BiocManager::install("argparser")'
RUN Rscript -e 'remotes::install_github("UW-GAC/AnvilDataModels")'

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
