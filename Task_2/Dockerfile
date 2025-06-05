FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y mysql-client sudo bash coreutils && \
    apt-get clean

COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/bin/bash"]
