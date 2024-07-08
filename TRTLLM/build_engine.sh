#!/bin/bash

# Setup ENV
## Output Path
OUTPUT_CKP_DIR=/workspace/checkpoints
OUTPUT_ENGINE_DIR=/workspace/engines

## Source Code Path
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/TensorRT-LLM

# Run Llama Example
cd $TRT_LLM_DIR/examples/llama

trtllm-build --checkpoint_dir $OUTPUT_CKP_DIR \
             --remove_input_padding enable \
             --gpt_attention_plugin float16 \
             --context_fmha enable \
             --gemm_plugin float16 \
             --output_dir $OUTPUT_ENGINE_DIR \
             --paged_kv_cache enable \
             --max_batch_size 8