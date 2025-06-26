#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/runtime-python:$line - << EOF
FROM python:$line
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
RUN mkdir -p /runtime && \
    pip install --upgrade pip && \
    pip config --user set global.index https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config --user set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config --user set global.trusted-host pypi.tuna.tsinghua.edu.cn && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
WORKDIR /runtime
EOF
done
