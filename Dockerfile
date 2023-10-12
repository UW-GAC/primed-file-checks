FROM uwgac/anvildatamodels:0.4.5

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/anvil-util-workflows.git

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
