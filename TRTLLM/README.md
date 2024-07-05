# Setup TensorRT-LLM on Kubernetes

## Clone Repository
```bash
apt-get update && apt-get -y install cmake git git-lfs
git clone https://github.com/REServeLLM/TensorRT-LLM.git

cd TensorRT-LLM
git submodule update --init --recursive
git lfs install
git lfs pull
```

## Quick Pull
```bash
docker pull harbor.act.buaa.edu.cn/nvidia/tensorrt-llm:v0.10.0-release

docker run -itd --ipc=host --ulimit memlock=-1 --ulimit stack=67108864  \
                --gpus=all \
                --env "CCACHE_DIR=/code/TensorRT-LLM/cpp/.ccache" \
                --env "CCACHE_BASEDIR=/code/TensorRT-LLM" \
                --workdir /app/tensorrt_llm \
                --hostname $(shell hostname) \
                --name tensorrt_llm \
                --tmpfs /tmp:exec \
                tensorrt-llm:v0.10.0-release
```

## Manual Make
```bash
cd TensorRT-LLM
# You can add CUDA_ARCHS to build selected SM, for example: make -C docker release_build CUDA_ARCHS="80-real;86-real"
make -C docker release_build

## equal to
DOCKER_BUILDKIT=1 docker build --pull  \
        --progress auto \
         --build-arg BASE_IMAGE=nvcr.io/nvidia/pytorch \
         --build-arg BASE_TAG=24.03-py3 \
         --build-arg BUILD_WHEEL_ARGS="--clean --trt_root /usr/local/tensorrt --python_bindings --benchmarks" \
         --build-arg TORCH_INSTALL_TYPE="skip" \
         --build-arg TRT_LLM_VER="0.10.0" \
         --build-arg GIT_COMMIT="d2868e5b1cbd79a51b6889305d5eb576c03aa4fc" \
         --target release \
        --file Dockerfile.multi \
        --tag tensorrt-llm:v0.10.0-release \

# Run docker
make -C docker release_run

## or Manually Run docker
docker run -itd --ipc=host --ulimit memlock=-1 --ulimit stack=67108864  \
                --gpus=all \
                --env "CCACHE_DIR=/code/TensorRT-LLM/cpp/.ccache" \
                --env "CCACHE_BASEDIR=/code/TensorRT-LLM" \
                --workdir /app/tensorrt_llm \
                --hostname $(shell hostname) \
                --name tensorrt_llm \
                --tmpfs /tmp:exec \
                tensorrt-llm:v0.10.0-release
```

### What Need Modified
We modified Dockerfile and Makefile to copy TensorRT-LLM into image rather than 'docker run --volume' or you can `docker cp` and `docker commit` to create a new image.
- `docker/Dockerfile.multi`:
    - ```Dockerfile
      COPY .. /code/TensorRT-LLM```

- `docker/Makefile`:
    - ```Makefile
      # Modify line 99
      DOCKER_RUN_OPTS   ?= -itd --ipc=host --ulimit memlock=-1 --ulimit stack=67108864
      # Modify line 103
      CODE_DIR          ?= /code/TensorRT-LLM
      # Delete line 199'
      --volume $(SOURCE_DIR):$(CODE_DIR) \```
      
## Running TensorRT-LLM

### Test Version
python3 -c "import tensorrt_llm"
