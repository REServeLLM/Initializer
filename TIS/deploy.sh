#!/bin/bash

set -e  # exit when any error happens

# Setup ENV
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct
OUTPUT_CKP_DIR=/workspace/checkpoints
OUTPUT_ENGINE_DIR=/workspace/engines
TRT_BACKEND_DIR=/workspace/tensorrtllm_backend
TRT_LLM_DIR=/workspace/tensorrtllm_backend/TensorRT-LLM

# Clone tensorrtllm_backend Repo
echo "Clone tensorrtllm_backend repo..."
if [ -d "$TRT_BACKEND_DIR" ]; then
  echo "Directory tensorrtllm_backend exists, skip cloning"
else
  cd /root
  git clone -b v0.10.0 https://

