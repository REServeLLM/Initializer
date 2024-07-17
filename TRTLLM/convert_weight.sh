#!/bin/bash

set -e

# Setup ENV
## Output path
BASE_CKP_DIR=/workspace/checkpoints
## Source code path
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/tensorrt_llm/examples/llama
## HuggingFace model name
MODEL_NAME=Meta-Llama-3-8B-Instruct
## HuggingFace model in PVC storage path
PVC_BASE_DIR=/mnt/models/models
PVC_MODEL_REPO="${PVC_BASE_DIR}/${MODEL_NAME}"
PVC_CKP_BASE_DIR=/mnt/models/checkpoints

# Default values for TP and PP
TP_SIZE=1
PP_SIZE=1

# Function to print help message
print_help() {
    echo "Usage: $0 [options]"
    echo "  --tp <size>   Optional. Set the tensor parallel size, default 1"
    echo "  --pp <size>   Optional. Set the pipeline parallel size, default 1"
    echo "  --help        Optional. Show this help message"
}

# Function to check if a value is a positive integer
is_positive_int() {
    if ! [[ $1 =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: --tp and --pp values must be positive integers."
        print_help
        exit 1
    fi
}

# Parse command line arguments for --tp and --pp
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tp)
            TP_SIZE="$2";
            is_positive_int $TP_SIZE
            shift 2 ;;
        --pp)
            PP_SIZE="$2";
            is_positive_int $PP_SIZE
            shift 2 ;;
        --help)
            print_help
            exit 0
            ;;
        *)
          echo "Unknown parameter passed: $1"
          print_help
          exit 1
          ;;
    esac
done

# Calculate GPU_SIZE
GPU_SIZE=$((TP_SIZE * PP_SIZE))
SUFFIX="-${GPU_SIZE}GPU-${TP_SIZE}TP-${PP_SIZE}PP"
# Construct OUTPUT_CKP_DIR
OUTPUT_CKP_DIR="${BASE_CKP_DIR}/${MODEL_NAME}${SUFFIX}"
PVC_OUTPUT_CKP_DIR="${PVC_CKP_BASE_DIR}/${MODEL_NAME}${SUFFIX}"

echo "Converting with the following parameters:"
echo "Model name: $MODEL_NAME"
echo "Model repository: $PVC_MODEL_REPO"
echo "Checkpoint output directory: $OUTPUT_CKP_DIR"
echo "Checkpoint pvc output directory: $PVC_OUTPUT_CKP_DIR"
echo "Tensor parallel size: $TP_SIZE"
echo "Pipeline parallel size: $PP_SIZE"

# Construct the command dynamically
CMD="python3 convert_checkpoint.py --model_dir $PVC_MODEL_REPO --output_dir $OUTPUT_CKP_DIR --dtype float16"

if [ "$TP_SIZE" -ne 1 ]; then
    CMD+=" --tp_size $TP_SIZE"
fi

if [ "$PP_SIZE" -ne 1 ]; then
    CMD+=" --pp_size $PP_SIZE"
fi

cd $TRT_LLM_DIR
echo "Calling command: $CMD"
eval $CMD

echo "Converting engines completed."