#!/usr/bin/env bash

set -e

# 指定 tag，默认 latest
tag="${1:-latest}"

authfile="$HOME/.docker/config.json"

# 镜像列表（只有简名，脚本自动组装源镜像和目标镜像）
images=(
  demo-vllm-qwen
  demo-3fsbuilder
  demo-3fs
  demo-ubuntu
  demo-sshd
  demo-alpine
  demo-fio
  demo-iperf3
  git
)

# 函数：列出镜像的所有 tag
list_image_tags() {
  local image_name="$1"
  local src_image="shaowenchen/${image_name}:${tag}"

  echo "==> Querying tags for $src_image"

  # 使用 skopeo 查询镜像的 tag 列表
  if docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 list-tags \
    docker://$src_image \
    --authfile /auth.json \
    --insecure-policy \
    --tls-verify=false 2>/dev/null; then
    echo "✓ Found tags for $src_image"
    return 0
  else
    echo "✗ No tags found for $src_image or image doesn't exist"
    return 1
  fi
}

# 函数：复制镜像
copy_image() {
  local name="$1"
  local src_image="shaowenchen-${name}:${tag}"

  # 从 name 中提取后缀用于目标 tag
  local suffix="${name#demo-}"    # 去掉 demo- 前缀
  suffix="${suffix#shaowenchen-}" # 万一写错成 shaowenchen-git 也能处理

  # 构建目标镜像名
  local dest_image
  if [[ "$tag" == "latest" ]]; then
    # 如果是 latest tag，目标镜像不包含 tag
    dest_image="shaowenchen/demo:${suffix}"
  else
    # 如果不是 latest，目标镜像包含 tag
    dest_image="shaowenchen/demo:${suffix}-${tag}"
  fi

  echo "==> Copying $src_image to $dest_image"

  docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 copy --multi-arch all \
    docker://$src_image \
    docker://$dest_image \
    --dest-authfile /auth.json \
    --insecure-policy \
    --src-tls-verify=false \
    --dest-tls-verify=false \
    --retry-times 1
}

echo "=== 开始查询镜像 tag ==="
echo "查询 tag: $tag"
echo

# 第一步：查询所有镜像的 tag
for name in "${images[@]}"; do
  if list_image_tags "$name"; then
    echo
  else
    echo "跳过不存在的镜像: $name"
    echo
  fi
done

echo "=== 开始复制镜像 ==="
echo

# 第二步：复制存在的镜像
for name in "${images[@]}"; do
  src_image="shaowenchen-${name}:${tag}"

  # 再次检查镜像是否存在（通过尝试列出 tag）
  if docker run --rm -v "$authfile":/auth.json quay.io/skopeo/stable:v1.13.0 list-tags \
    docker://$src_image \
    --authfile /auth.json \
    --insecure-policy \
    --tls-verify=false >/dev/null 2>&1; then

    copy_image "$name"
    echo "✓ 复制完成: $name"
  else
    echo "✗ 跳过不存在的镜像: $name"
  fi
  echo
done

echo "=== 所有操作完成 ==="
