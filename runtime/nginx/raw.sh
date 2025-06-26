#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/runtime-nginx:$line - << EOF
FROM ubuntu:22.04
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
ENV NGINX_VERSION=$line
RUN mkdir -p /runtime && \
    adduser --system --no-create-home --disabled-login --group nginx && \
    apt-get update && \
    apt-get install -y \
    curl \
    wget \
    build-essential \
    zlib1g-dev \
    libpcre3-dev \
    libssl-dev && \
    wget https://nginx.org/download/nginx-\$NGINX_VERSION.tar.gz && \
    tar -zxvf nginx-\$NGINX_VERSION.tar.gz --remove-files && \
    cd nginx-\$NGINX_VERSION && \
    ./configure --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/ --with-http_ssl_module --with-ipv6 --with-threads --with-stream --with-stream_ssl_module && \
    make && \
    make install && \
    rm -rf ../nginx-\$NGINX_VERSION && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
WORKDIR /runtime
EXPOSE 80
CMD ["/usr/sbin/nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
EOF
done
