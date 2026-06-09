# shaowenchen/demo:wan-video-2.2
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
    PATH=/usr/local/cuda/bin:$PATH

RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    ninja-build \
    pkg-config \
    ffmpeg \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel

WORKDIR /app

RUN git clone https://github.com/Wan-Video/Wan2.2.git . && \
    git checkout main

RUN pip install --no-cache-dir \
    "torch==2.7.1" \
    "torchvision==0.22.1" \
    "torchaudio==2.7.1" \
    --index-url https://download.pytorch.org/whl/cu128

RUN pip install \
    "opencv-python>=4.9.0.80" \
    "diffusers>=0.31.0" \
    "transformers>=4.49.0,<=4.51.3" \
    "tokenizers>=0.20.3" \
    "accelerate>=1.1.1" \
    tqdm \
    easydict \
    ftfy \
    dashscope \
    imageio-ffmpeg \
    "numpy>=1.23.5,<2"

ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0;12.0"
RUN pip install --no-cache-dir --no-build-isolation "flash-attn==2.7.4.post1"

RUN pip install \
    openai-whisper \
    HyperPyYAML \
    onnxruntime \
    inflect \
    wetext \
    omegaconf \
    conformer \
    hydra-core \
    lightning \
    rich \
    gdown \
    matplotlib \
    wget \
    pyarrow \
    pyworld \
    librosa \
    decord \
    modelscope \
    GitPython \
    imageio

RUN pip install \
    peft \
    pandas \
    loguru \
    sentencepiece

RUN mkdir -p /app/models

CMD ["/bin/bash"]