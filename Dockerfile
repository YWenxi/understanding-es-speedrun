FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

ARG UBUNTU_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu

RUN sed -i \
    -e "s|http://archive.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" \
    -e "s|http://security.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" \
    /etc/apt/sources.list

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl \
    wget \
    vim \
    tmux \
    htop \
    build-essential \
    openssh-client \
    ca-certificates \
    libgl1 \
    libglib2.0-0 \
    libnuma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.28 \
    /uv /uvx /usr/local/bin/

# Python environment outside the workspace
ENV UV_PYTHON_INSTALL_DIR=/opt/python
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV UV_LINK_MODE=copy

RUN uv python install 3.13

ENV PATH="/opt/venv/bin:$PATH"

# Install locked dependencies only
WORKDIR /opt/dependencies

COPY pyproject.toml uv.lock ./

RUN uv sync \
    --locked \
    --extra dev \
    --no-install-project

# Persistent cache directories
ENV HF_HOME=/cache/huggingface
ENV UV_CACHE_DIR=/cache/uv
ENV TRITON_CACHE_DIR=/cache/triton

WORKDIR /workspace

CMD ["/bin/bash"]