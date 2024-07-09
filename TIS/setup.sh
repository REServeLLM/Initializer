#!/bin/bash

set -e

kubectl apply -f config/trtllm-clusterservingruntime.yaml

# Update the submodules
cd tensorrtllm_backend
git lfs install
git submodule update --init --recursive

# Use the Dockerfile to build the backend in a container
# For Network Issue
#DOCKER_BUILDKIT=1 docker build -t reserve-llm:latest \
#                               --progress auto \
#                               --network host \
#                               -f dockerfile/Dockerfile.trt_llm_backend_network_proxy .
# For No Network Issue
DOCKER_BUILDKIT=1 docker build -t reserve-llm:latest \
                               --progress auto \
                               -f dockerfile/Dockerfile.trt_llm_backend .

