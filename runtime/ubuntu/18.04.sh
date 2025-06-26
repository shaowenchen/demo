#!/bin/sh

docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/runtime-ubuntu:18.04 - << EOF
FROM ubuntu:18.04
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
RUN mkdir -p /runtime && \
    apt-get -y update && \
    apt-get -y install python3-pip vim tzdata wget curl xz-utils bash gettext ca-certificates && \
    wget https://raw.githubusercontent.com/shaowenchen/ops-hub/refs/heads/master/mirror/ubuntu/18.04.bionic.aliyun.sources.list -O /etc/apt/sources.list && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
WORKDIR /runtime
EOF
