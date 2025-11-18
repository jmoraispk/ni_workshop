FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Dependencies needed so the script can run
RUN apt-get update && \
    apt-get install -y sudo wget git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Workdir where local files will be mounted
WORKDIR /home

CMD ["/bin/bash"]

