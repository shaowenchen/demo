#!/bin/sh

for line in $(cat tag); do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/builder-golang:$line - <<EOF
FROM golang:$line
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
RUN mkdir -p /builder && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=on && \
    go env -w GOPROXY=https://mirrors.aliyun.com/goproxy,direct && \
    wget https://github.com/swaggo/swag/releases/download/v1.16.4/swag_1.16.4_Linux_x86_64.tar.gz && \
    tar -xvf swag_1.16.4_Linux_x86_64.tar.gz -C /bin/ && rm -rf swag*
WORKDIR /builder
EOF
done
