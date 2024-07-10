#!/bin/bash

# Setup ENV
## Output Path
OUTPUT_CKP_DIR=/workspace/checkpoints

## Source Code Path
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/TensorRT-LLM

## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct

# Run Llama Example
cd $TRT_LLM_DIR/examples/llama

# TODO: save the converted checkpoints to PVC storage
python3 convert_checkpoint.py --model_dir $MODEL_REPO_DIR --output_dir $OUTPUT_CKP_DIR --dtype float16