#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm,linux/arm64,linux/amd64 -t shaowenchen/builder-node:$line - << EOF
FROM shaowenchen/runtime-node:$line
RUN mkdir -p builder && \
    npm config set registry http://registry.npm.taobao.org/ && \
    npm config set fetch-retry-maxtimeout 600000 -g && \
    npm config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass && \
    npm config set phantomjs_cdnurl https://cdn.npm.taobao.org/dist/phantomjs/ && \
    npm config set chromedriver_cdnurl https://cdn.npm.taobao.org/dist/chromedriver && \
    npm config set operadriver_cdnurl https://cdn.npm.taobao.org/dist/operadriver && \
    npm config set fse_binary_host_mirror https://cdn.npm.taobao.org/dist/fsevents && \
    npm config set prefer-offline true || true && \
    yarn config set registry http://registry.npm.taobao.org/ && \
    yarn config set network-timeout 600000 && \
    yarn config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass && \
    yarn config set phantomjs_cdnurl https://cdn.npm.taobao.org/dist/phantomjs/ && \
    yarn config set chromedriver_cdnurl https://cdn.npm.taobao.org/dist/chromedriver && \
    yarn config set operadriver_cdnurl https://cdn.npm.taobao.org/dist/operadriver && \
    yarn config set fse_binary_host_mirror https://cdn.npm.taobao.org/dist/fsevents && \
    yarn config set install.prefer-offline true || true
WORKDIR /builder
EOF
done
