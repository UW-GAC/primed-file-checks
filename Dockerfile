FROM bioconductor/bioconductor_docker:devel
    
RUN Rscript -e 'BiocManager::install("AnVIL")'
RUN Rscript -e 'remotes::install_github("UW-GAC/AnvilDataModels")'

RUN cd /usr/local  && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
