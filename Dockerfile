FROM uwgac/anvildatamodels:0.7.0

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/anvil-util-workflows.git

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
