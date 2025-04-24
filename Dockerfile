##############
# Build stage
##############

FROM ubuntu:24.04 AS builder

ADD https://astral.sh/uv/install.sh /install.sh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    cmake \
    g++ \
    python3-dev \
    ca-certificates \
    ccache \
    build-essential \
    lsb-release \
    software-properties-common \
    gnupg && \
    chmod +x /install.sh && \
    ./install.sh

ENV PATH="/root/.local/bin:${PATH}"
WORKDIR /
RUN git clone --recursive https://github.com/microsoft/BitNet.git

# Installs the dependencies, downloads the model and builds the server
WORKDIR /BitNet
RUN uv venv && \
    . .venv/bin/activate && \
    uv pip install pip && \
    uv pip install -r requirements.txt --index-strategy unsafe-best-match && \
    uv pip install -r 3rdparty/llama.cpp/requirements/requirements-all.txt && \
    huggingface-cli download microsoft/BitNet-b1.58-2B-4T-gguf --local-dir models/BitNet-b1.58-2B-4T && \
    python setup_env.py -md models/BitNet-b1.58-2B-4T -q i2_s

WORKDIR /BitNet/build
RUN cmake .. -DLLAMA_BUILD_SERVER=ON && \
    cmake --build . --config Release

########################
# Final stage
########################

FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgomp1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    useradd modeluser && \
    mkdir -p /home/modeluser/BitNet && \
    chown -R modeluser:modeluser /home/modeluser/BitNet

# Copy the application and its lzibrary
COPY --from=builder /BitNet/ /home/modeluser/BitNet/
COPY --from=builder /BitNet/build/3rdparty/llama.cpp/src/libllama.so /usr/lib/
COPY --from=builder /BitNet/build/3rdparty/llama.cpp/ggml/src/libggml.so /usr/lib/

USER modeluser
WORKDIR /home/modeluser/BitNet

ENTRYPOINT ["./build/bin/llama-server", "-m", "models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf", "--host", "0.0.0.0"]
