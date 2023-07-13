FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    vim \
    mtr \
    net-tools \
    fio \
    speedtest-cli \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/cache/apt/* \
    && rm -rf /root/.cache \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash" , "-c" , "while true; do sleep 100; done"]
