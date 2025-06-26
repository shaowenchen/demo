#!/bin/bash

set -e

# 默认使用 latest tag
tag="${1:-latest}"

authfile="$HOME/.docker/config.json"

# 镜像列表
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

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

echo "=== 镜像同步任务启动 ==="
log "使用 tag: $tag"
echo "==========================="
echo

# 直接执行copy同步
for img in "${images[@]}"; do
    echo "--> 处理镜像: $img"
    
    # 获取当前镜像的tag列表
    if ! src_tags=$(docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 list-tags \
        docker://"$img" \
        --authfile /auth.json \
        --insecure-policy \
        --tls-verify=false 2>/dev/null | jq -r '.Tags[]'); then
        echo "✗ 跳过: 无法获取 $img 的tag"
        echo
        continue
    fi
    
    # 构造目标镜像名称
    base="${img##*/}"  # 去掉前缀，保留 demo-xxx
    suffix="${base#demo-}"  # 去除 demo- 前缀
    
    # 处理每个tag
    tag_count=0
    for tag_item in $src_tags; do
        # 构造源镜像和目标镜像
        src_image="${img}:${tag_item}"
        
        if [[ "$tag_item" == "latest" ]]; then
            dest_image="shaowenchen/demo:${suffix}"
        else
            dest_image="shaowenchen/demo:${suffix}-${tag_item}"
        fi
        
        log "复制: $src_image -> $dest_image"
        
        # 执行copy操作
        output=$(docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 copy \
            --multi-arch all docker://"$src_image" docker://"$dest_image" \
            --dest-authfile /auth.json \
            --insecure-policy \
            --src-tls-verify=false \
            --dest-tls-verify=false \
            --retry-times 0 2>&1)
        
        status=$?
        
        if [[ $output == *"toomanyrequests"* ]]; then
            log "失败: 请求过多限制 - $src_image"
            echo "$output"
            break 2
        elif [ $status -ne 0 ]; then
            log "失败: $src_image -> $dest_image"
            echo "$output"
            break 1
        else
            log "成功: $src_image -> $dest_image"
            ((tag_count++))
        fi
    done
    
    echo "✓ 完成镜像: $img (复制了 $tag_count 个tag)"
    echo
done

echo "=== 所有镜像同步完成 ==="
