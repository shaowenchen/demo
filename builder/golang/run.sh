#!/bin/sh

for line in $(cat tag); do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/builder-golang:$line - <<EOF
FROM golang:$line
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
RUN mkdir -p /builder && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=on && \
    go env -w GOPROXY=https://mirrors.aliyun.com/goproxy,direct
WORKDIR /builder
EOF
done
