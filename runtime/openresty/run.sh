#!/bin/sh

for line in $(cat tag)
do
    echo $line
    # docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/runtime-openresty:$line - << EOF
    docker buildx build --push --platform=linux/amd64 -t shaowenchen/runtime-openresty:$line - << EOF
FROM openresty/openresty:$line
LABEL maintainer="shaowenchen <mail@chenshaowen.com>"
ENV LUA_PROM_VERSION=0.20230607
RUN mkdir -p /runtime && \
    curl -LO https://github.com/knyar/nginx-lua-prometheus/archive/refs/tags/\$LUA_PROM_VERSION.tar.gz && \
    tar -zxvf \$LUA_PROM_VERSION.tar.gz --remove-files && \
    mv nginx-lua-prometheus-\$LUA_PROM_VERSION /usr/local/openresty/lualib/nginx-lua-prometheus && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
WORKDIR /runtime
EXPOSE 80
CMD ["/usr/local/openresty/bin/openresty", "-c", "/usr/local/openresty/nginx/conf/nginx.conf", "-g", "daemon off;"]
EOF
done
