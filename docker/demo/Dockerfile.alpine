FROM alpine

RUN apk update && \
    apk upgrade && \
    apk add --update alpine-sdk && \
    apk add --no-cache \
    bash \
    git \
    openssh \
    make \
    cmake \
    busybox-extras \
    mtr \
    python3 \
    iptables \
    speedtest-cli && \
    apk cache clean && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

WORKDIR /var/log/

CMD ["python3", "-m", "http.server", "80"]
