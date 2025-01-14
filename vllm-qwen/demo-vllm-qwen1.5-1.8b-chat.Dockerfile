FROM vllm/vllm-openai:latest
RUN apt-get install git-lfs -y
RUN mkdir -p /models && cd /models
RUN git clone https://huggingface.co/Qwen/Qwen1.5-1.8B-Chat && cd Qwen1.5-1.8B-Chat && git lfs pull && rm -rf .git 
