#!/bin/sh

for line in $(cat tag); do
    echo $line
    cat >Dockerfile.$line <<EOF
FROM nvidia/cuda:$line

ENV HOST 0.0.0.0

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y git build-essential \
        python3 python3-pip gcc wget \
        ocl-icd-opencl-dev opencl-headers clinfo \
        libclblast-dev libopenblas-dev && \
    mkdir -p /etc/OpenCL/vendors && echo "libnvidia-opencl.so.1" >/etc/OpenCL/vendors/nvidia.icd

# setting build related env vars
ENV CUDA_DOCKER_ARCH=all
ENV LLAMA_CUBLAS=1

# Install depencencies
RUN python3 -m pip install --upgrade pip pytest cmake scikit-build setuptools fastapi uvicorn sse-starlette pydantic-settings starlette-context

# Install llama-cpp-python (build with cuda)
RUN CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install llama-cpp-python

# Run the server
CMD python3 -m llama_cpp.server
EOF
    docker buildx build --push --platform=linux/arm64,linux/amd64 -t shaowenchen/llama-cpp-python:$line -f Dockerfile.$line .
    rm Dockerfile.$line
done
