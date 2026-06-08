# shaowenchen/demo:wan-video-2.2
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

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

RUN pip install "torch>=2.4.0" "torchvision>=0.19.0" torchaudio --index-url https://download.pytorch.org/whl/cu124

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

RUN pip install --no-build-isolation flash_attn

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
    GitPython

RUN pip install \
    peft \
    pandas \
    loguru \
    sentencepiece

RUN pip install --no-build-isolation -e git+https://github.com/facebookresearch/sam2.git@0e78a118995e66bb27d78518c4bd9a3e95b4e266#egg=SAM-2

RUN mkdir -p /app/models

CMD ["/bin/bash"]