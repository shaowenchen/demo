FROM ubuntu:20.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    python3 \
    iptables && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

WORKDIR /var/log/

CMD ["python3", "-m", "http.server", "80"]
