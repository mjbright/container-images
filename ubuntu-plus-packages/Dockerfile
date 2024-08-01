
FROM ubuntu:24.04

RUN apt-get update -y && \
    apt-get install -y curl wget httpie dnsutils iputils-ping  && \
    apt-get clean

#iputils-ping iputils-arping inetutils-ping

CMD ["/bin/bash"]

