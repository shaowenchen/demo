#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/runtime-nginx:$line-vts - << EOF
FROM ubuntu:22.04
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
ENV NGINX_VERSION=$line
ENV NGINX_VTS_VERSION=0.2.2
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
    wget https://github.com/vozlt/nginx-module-vts/archive/v\$NGINX_VTS_VERSION.tar.gz && \
    tar -zxvf v\$NGINX_VTS_VERSION.tar.gz --remove-files && \
    cd nginx-\$NGINX_VERSION && \
    ./configure --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/ --with-http_ssl_module --with-ipv6 --with-threads --with-stream --with-stream_ssl_module --add-dynamic-module=../nginx-module-vts-\$NGINX_VTS_VERSION && \
    make && \
    make install && \
    rm -rf ../nginx-\$NGINX_VERSION && \
    rm -rf ../nginx-module-vts-\$NGINX_VTS_VERSION && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
WORKDIR /runtime
EXPOSE 80
CMD ["/usr/sbin/nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
EOF
done
