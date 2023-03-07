FROM uwgac/anvildatamodels:0.2.7

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/anvil-util-workflows.git

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
