#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/builder-python:$line - << EOF
FROM shaowenchen/runtime-python:$line
RUN mkdir -p /builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ninja-build && \
    build-essential && \
    rm -rf /var/lib/apt/lists/* || true
WORKDIR /builder
EOF
done
