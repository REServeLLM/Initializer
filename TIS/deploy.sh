#!/bin/bash

### We have copy TensorRT-LLM and tensorrtllm_backend source code in image!
### But it's better to pull the latest code before deploying to KServe cluster!


set -e  # exit when any error happens

# Setup ENV

## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct

## Source Code Path
TRT_BACKEND_DIR=/code/tensorrtllm_backend
TRT_LLM_DIR=/code/tensorrtllm_backend/TensorRT-LLM

## Output Path
OUTPUT_CKP_DIR=/workspace/checkpoints
OUTPUT_ENGINE_DIR=/workspace/engines



