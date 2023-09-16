FROM uwgac/anvildatamodels:0.4.3.1

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/anvil-util-workflows.git

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
