#!/bin/bash

set -e

# Setup ENV
## Source Code Path
TIS_DIR=/code/REServe/tensorrtllm_backend
## Triton Model Repo Path
TRITON_MODEL_REPO=/code/REServe/tensorrtllm_backend/triton_model_repo
## HuggingFace Model in PVC Storage Path
## TODO: next time we need to test if the tokenizer is only needed and just copy the tokenizer to workspace
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct
## Triton Max Batch Size, must be the same as the parameter in building the engine
TRITON_MAX_BATCH_SIZE=64
## Output Path
### example: /workspace/engines/Meta-Llama-3-8B-Instruct-2GPU-2TP-1PP
OUTPUT_DIR=""

# Usage information
print_help() {
    echo "Usage: $0 --output_dir <path> --world_size <number> --triton_max_batch_size <number> [--model_repo_dir <path>] [--help]"
    echo "Options:"
    echo "  --output_dir              Required. Directory where the engines saved."
    echo "  --world_size              Required. Number of required GPU to launch."
    echo "  --triton_max_batch_size   Required. Maximum batch size for Triton, same as build parameter max_batch_size."
    echo "  --model_repo_dir          Optional. Directory containing the huggingface model tokenizer. Default value: /mnt/models/models/Meta-Llama-3-8B-Instruct"
    echo "  --help                    Optional. Display this help message and exit."
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --output_dir) OUTPUT_DIR="$2"; shift 2 ;;
        --world_size) WORLD_SIZE="$2"; shift 2 ;;
        --triton_max_batch_size) TRITON_MAX_BATCH_SIZE="$2"; shift 2 ;;
        --model_repo_dir) MODEL_REPO_DIR="$2"; shift 2 ;;
        --help) print_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; print_help; exit 1 ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$OUTPUT_DIR" || -z "$WORLD_SIZE" || -z "$TRITON_MAX_BATCH_SIZE" ]]; then
    echo "Error: --output_dir, --world_size, and --triton_max_batch_size are required."
    print_help
    exit 1
fi

# Prepare Configs
cp $TIS_DIR/all_models/inflight_batcher_llm/* $TRITON_MODEL_REPO -r

python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/preprocessing/config.pbtxt tokenizer_dir:"${MODEL_REPO_DIR}",triton_max_batch_size:"${TRITON_MAX_BATCH_SIZE}",preprocessing_instance_count:1
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/postprocessing/config.pbtxt tokenizer_dir:"${MODEL_REPO_DIR}",triton_max_batch_size:"${TRITON_MAX_BATCH_SIZE}",postprocessing_instance_count:1
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/tensorrt_llm_bls/config.pbtxt triton_max_batch_size:"${TRITON_MAX_BATCH_SIZE}",decoupled_mode:False,bls_instance_count:1,accumulate_tokens:False
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/ensemble/config.pbtxt triton_max_batch_size:"${TRITON_MAX_BATCH_SIZE}"
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/tensorrt_llm/config.pbtxt triton_backend:tensorrtllm,triton_max_batch_size:"${TRITON_MAX_BATCH_SIZE}",decoupled_mode:False,max_beam_width:1,engine_dir:"${OUTPUT_DIR}",max_tokens_in_paged_kv_cache:1280,max_attention_window_size:1280,kv_cache_free_gpu_mem_fraction:0.5,exclude_input_in_output:True,enable_kv_cache_reuse:False,batching_strategy:inflight_fused_batching,max_queue_delay_microseconds:0

# Launch Triton Server
# pip install SentencePiece  # already installed
python3 $TIS_DIR/scripts/launch_triton_server.py --world_size "${WORLD_SIZE}" --model_repo=${TRITON_MODEL_REPO} --http_port=8080 --grpc_port=9000 --metrics_port=8002
