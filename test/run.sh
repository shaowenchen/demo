#!/bin/bash

set -e

authfile="$HOME/.docker/config.json"

images=(
    shaowenchen/demo-3fs
    shaowenchen/demo-3fsbuilder
    shaowenchen/demo-pytorch3d
    shaowenchen/demo-fio
    shaowenchen/demo-alpine
    shaowenchen/demo-sshd
    shaowenchen/demo-ubuntu
    shaowenchen/demo-iperf3
    shaowenchen/demo-fluid-3fs
    shaowenchen/demo-vllm-qwen
    shaowenchen/demo-nginx-vts-exporter
    shaowenchen/demo-nginx-vts
    shaowenchen/demo-nginx-stream
    shaowenchen/demo-whoami
    shaowenchen/demo-fluid-s3fs
    shaowenchen/demo-fluid-lustre
)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

for img in "${images[@]}"; do
    base="${img##*/}"
    suffix="${base#demo-}"

    if ! src_tags=$(docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 list-tags \
        docker://"$img" \
        --authfile /auth.json \
        --insecure-policy \
        --tls-verify=false 2>/dev/null | jq -r '.Tags[]'); then
        log "跳过镜像: $img（无法获取 tag 列表）"
        continue
    fi

    for tag_item in $src_tags; do
        src_image="${img}:${tag_item}"

        if [[ "$tag_item" == "latest" ]]; then
            dest_image="shaowenchen/demo:${suffix}"
        # 若 tag 中包含 "-latest"（例如 latest-arm64），移除该部分
        elif [[ "$tag_item" == *"-latest"* ]]; then
            # 去掉所有的 -latest 子串
            tag_item_cleaned="${tag_item//-latest/}"
            dest_image="shaowenchen/demo:${suffix}-${tag_item_cleaned}"
        # 跳过包含 nydus 的 tag
        elif [[ "$tag_item" == *"-nydus"* ]]; then
            log "跳过镜像: $src_image（包含 nydus）"
            continue
        else
            dest_image="shaowenchen/demo:${suffix}-${tag_item}"
        fi


        log "复制: $src_image -> $dest_image"

        docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 copy \
            --multi-arch all docker://"$src_image" docker://"$dest_image" \
            --dest-authfile /auth.json \
            --insecure-policy \
            --src-tls-verify=false \
            --dest-tls-verify=false \
            --retry-times 0

    done

done

echo
log "镜像同步任务结束"
