#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DATA_DIR="${COMFYUI_DATA_DIR:-/data/.studio/comfyui}"

mkdir -p \
  "${COMFYUI_INPUT_DIR:-${COMFYUI_DATA_DIR}/input}" \
  "${COMFYUI_OUTPUT_DIR:-${COMFYUI_DATA_DIR}/output}" \
  "${COMFYUI_USER_DIR:-${COMFYUI_DATA_DIR}/user}"

cd /comfyui
exec python3 main.py \
  --listen 0.0.0.0 \
  --port "${COMFYUI_PORT:-8188}" \
  --enable-manager \
  --input-directory "${COMFYUI_INPUT_DIR:-${COMFYUI_DATA_DIR}/input}" \
  --output-directory "${COMFYUI_OUTPUT_DIR:-${COMFYUI_DATA_DIR}/output}" \
  --user-directory "${COMFYUI_USER_DIR:-${COMFYUI_DATA_DIR}/user}" \
  "$@"
