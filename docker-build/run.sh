#!/bin/sh

for line in $(cat tag)
do
    echo $line
    cat <<EOF > Dockerfile
FROM golang:$line
RUN go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/
EOF
    docker build -t shaowenchen/golang:$line . -f Dockerfile
done

