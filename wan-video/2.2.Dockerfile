# shaowenchen/demo:wan-video-2.2
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
    PATH=/usr/local/cuda/bin:$PATH

WORKDIR /app

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        libgomp1; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
    pip install --no-cache-dir \
        "torch>=2.4.0" \
        "torchvision>=0.19.0" \
        torchaudio \
        --index-url https://download.pytorch.org/whl/cu124; \
    \
    pip install --no-cache-dir \
        "opencv-python>=4.9.0.80" \
        "diffusers>=0.31.0" \
        "transformers>=4.49.0,<=4.51.3" \
        "tokenizers>=0.20.3" \
        "accelerate>=1.1.1" \
        "numpy>=1.23.5,<2" \
        dashscope \
        easydict \
        ftfy \
        imageio-ffmpeg \
        tqdm; \
    pip install --no-cache-dir --no-build-isolation flash_attn; \
    \
    pip install --no-cache-dir \
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
        peft \
        pandas \
        loguru \
        sentencepiece

RUN set -eux; \
    git clone https://github.com/Wan-Video/Wan2.2.git .; \
    git checkout main; \
    mkdir -p /app/models

CMD ["/bin/bash"]