FROM nvidia/cuda:11.6.0-cudnn8-runtime-ubuntu20.04

# works with cuda 11.6, for other cuda replace initial docker to 11.3.0 and corresponding magma-cuda113, whl/cu113

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update \
    && apt-get install -y build-essential \
    && apt-get install -y ca-certificates \
    && apt-get install -y ccache \
    && apt-get install -y cmake \
    && apt-get install -y curl \
    && apt-get install -y file \
    && apt-get install -y sudo \
    && apt-get install -y git \
    && apt-get install -y wget \
    && apt-get install -y locales

# Install base utilities
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda install astunparse numpy ninja pyyaml setuptools cmake cffi typing_extensions future six requests dataclasses
RUN conda install mkl mkl-include
RUN conda install -c pytorch magma-cuda116  # or the magma-cuda* that matches your CUDA version from https://anaconda.org/pytorch/repo


# install torch from source
RUN git clone --recursive https://github.com/pytorch/pytorch
WORKDIR pytorch
RUN git submodule sync
RUN git submodule update --init --recursive --jobs 0

ENV PYTORCH_BUILD_VERSION=1.13.0
ENV PYTORCH_BUILD_NUMBER=1
ENV USE_CUDA=1 USE_CUDNN=1
# exact versions can be selected from here: TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX 8.0"
ENV TORCH_CUDA_ARCH_LIST="8.0" TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
ENV CMAKE_PREFIX_PATH="$(dirname $(which conda))/../"
ENV MAX_JOBS=16
RUN python setup.py clean \
    && python setup.py install

RUN pip3 install torchvision --extra-index-url https://download.pytorch.org/whl/cu116 --no-deps

# Build command:
# DOCKER_BUILDKIT=1 docker build --tag torch_latest .

# Usage as base image in other Dockerfiles:
# FROM torch_latest:latest