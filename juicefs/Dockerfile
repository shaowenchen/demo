# shaowenchen/demo:juicefs-fdb-7.4.6
FROM golang:1.25-bookworm AS builder

ARG TARGETARCH
ARG JUICEFS_REPO_URL=https://github.com/juicedata/juicefs
ARG JUICEFS_REPO_REF=main
ARG FDB_VERSION=7.4.6
ARG GOPROXY=https://proxy.golang.org,direct

ENV GOPROXY=${GOPROXY}
WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git musl-tools wget && \
  wget -O /tmp/fdb.deb "https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients_${FDB_VERSION}-1_${TARGETARCH}.deb" && \
  dpkg -i /tmp/fdb.deb || apt-get install -f -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

RUN git clone "${JUICEFS_REPO_URL}" juicefs && \
    cd juicefs && \
    git fetch --depth 1 origin "${JUICEFS_REPO_REF}" && \
    git checkout FETCH_HEAD

WORKDIR /workspace/juicefs
RUN make juicefs.fdb && \
    install -D -m 0755 juicefs.fdb /opt/juicefs/bin/juicefs && \
    /opt/juicefs/bin/juicefs --version

FROM debian:bookworm-slim

ARG TARGETARCH
ARG FDB_VERSION=7.4.6

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl fuse3 wget && \
  wget -O /tmp/fdb.deb "https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients_${FDB_VERSION}-1_${TARGETARCH}.deb" && \
  dpkg -i /tmp/fdb.deb || apt-get install -f -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=builder /opt/juicefs/bin/juicefs /opt/juicefs/bin/juicefs
ENV PATH="/opt/juicefs/bin:${PATH}"

RUN ln -sf /opt/juicefs/bin/juicefs /bin/mount.juicefs

ENTRYPOINT ["/opt/juicefs/bin/juicefs"]
CMD ["--help"]
