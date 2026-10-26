FROM ubuntu:22.04

LABEL maintainer="TPU Project"
LABEL description="Docker container for 4x4 TPU Systolic Array - RTL to GDSII"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    vim \
    python3 \
    python3-pip \
    iverilog \
    gtkwave \
    yosys \
    nextpnr \
    graphviz \
    imagemagick \
    tcl \
    tcl-dev \
    flex \
    bison \
    libffi-dev \
    libreadline-dev \
    libfl-dev \
    libcmocka-dev \
    libyaml-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /design
RUN mkdir -p /design/rtl /design/verif /design/synth /design/test

# Copy project files
COPY . /design/

# Make scripts executable
RUN chmod +x /design/run_sim.sh

# Default command: bash shell
CMD ["/bin/bash"]

# Build instructions:
# docker build -t tpu-design:latest .
# docker run -it -v $(pwd):/design tpu-design:latest

# Run simulation:
# docker run -it -v $(pwd):/design tpu-design:latest bash run_sim.sh
