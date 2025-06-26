#!/usr/bin/env bash

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

# 检查镜像是否存在
image_exists() {
  local image="$1"

  docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 list-tags \
    docker://"$image" \
    --authfile /auth.json \
    --insecure-policy \
    --tls-verify=false > /dev/null 2>&1
}

# 构造目标镜像名称
build_dest_image() {
  local full_image="$1"
  local base="${full_image##*/}"  # 去掉前缀，保留 demo-xxx

  # 去除 demo- 前缀
  local suffix="${base#demo-}"

  if [[ "$tag" == "latest" ]]; then
    echo "shaowenchen/demo:${suffix}"
  else
    echo "shaowenchen/demo:${suffix}-${tag}"
  fi
}

# 复制镜像
copy_image() {
  local src_image="$1"
  local dest_image="$2"

  echo "==> Copying $src_image -> $dest_image"

  docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 copy --multi-arch all \
    docker://"$src_image" \
    docker://"$dest_image" \
    --dest-authfile /auth.json \
    --insecure-policy \
    --src-tls-verify=false \
    --dest-tls-verify=false \
    --retry-times 1
}

echo "=== 镜像同步任务启动 ==="
echo "使用 tag: $tag"
echo "==========================="
echo

for img in "${images[@]}"; do
  src_image="${img}:${tag}"
  echo "--> 检查镜像是否存在: $src_image"

  if image_exists "$img"; then
    dest_image=$(build_dest_image "$img")
    copy_image "$src_image" "$dest_image"
    echo "✓ 完成: $img"
  else
    echo "✗ 跳过: 镜像不存在或 tag 无效 - $src_image"
  fi
  echo
done

echo "=== 所有镜像同步完成 ==="
