#!/bin/bash

### We have copy TensorRT-LLM and tensorrtllm_backend source code in image!
### But it's better to pull the latest code before deploying to KServe cluster!


set -e  # exit when any error happens

# Setup ENV

## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct

## Source Code Path
TRT_BACKEND_DIR=/code/REServe/tensorrtllm_backend
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/TensorRT-LLM

## Output Path
OUTPUT_CKP_DIR=/workspace/checkpoints
OUTPUT_ENGINE_DIR=/workspace/engines

# Run Llama Example
cd $TRT_LLM_DIR/examples/llama
# pip install -r requirements.txt
# apt-get update
# apt-get install git-lfs

# Convert Checkpoint
python3 convert_checkpoint.py --model_dir $MODEL_REPO_DIR --output_dir $OUTPUT_CKP_DIR --dtype float16
# Build Engine
trtllm-build --checkpoint_dir $OUTPUT_CKP_DIR \
             --remove_input_padding enable \
             --gpt_attention_plugin float16 \
             --context_fmha enable \
             --gemm_plugin float16 \
             --output_dir $OUTPUT_ENGINE_DIR \
             --paged_kv_cache enable \
             --max_batch_size 8

# Test Inference
python3 ../run.py --input_text "Hello, please tell me a joke." \
                  --max_output_len 100 \
                  --tokenizer_dir $MODEL_REPO_DIR \
                  --engine_dir $OUTPUT_ENGINE_DIR



