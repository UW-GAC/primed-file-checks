FROM uwgac/anvildatamodels:0.1.1

RUN cd /usr/local && \
    git clone https://github.com/UW-GAC/primed-file-checks.git
