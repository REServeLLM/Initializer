#!/bin/bash

# Setup ENV
## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct
## Source Code Path
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/TensorRT-LLM
## Output Path
OUTPUT_ENGINE_DIR=/workspace/engines

cd $TRT_LLM_DIR/examples/llama

python3 ../run.py --input_text "Hello, please tell me a joke." \
                  --max_output_len 50 \
                  --tokenizer_dir $MODEL_REPO_DIR \
                  --engine_dir $OUTPUT_ENGINE_DIR