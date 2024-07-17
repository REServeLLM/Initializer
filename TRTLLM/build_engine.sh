#!/bin/bash

set -e

# Setup ENV
## HuggingFace model name
MODEL_NAME=Meta-Llama-3-8B-Instruct
## Converted model checkpoint directory
CHECKPOINT_DIR=""
OUTPUT_DIR=""
PVC_OUTPUT_DIR=""
MAX_BATCH_SIZE=64

print_help() {
    echo "Usage: $0 --checkpoint_dir <path> --output_dir <path> --max_batch_size <number> [--help]"
    echo "Options:"
    echo "  --checkpoint_dir  Required. Directory containing the converted model checkpoint."
    echo "  --output_dir      Required. Directory where the built engines will be saved."
    echo "  --max_batch_size  Required. Maximum batch size."
    echo "  --help            Optional. Display this help message and exit."
}

# Parse command line arguments for --checkpoint_dir and --output_dir
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --checkpoint_dir)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --checkpoint_dir requires a <path>."
                print_help
                exit 1
            fi
            CHECKPOINT_DIR="$2";
            shift 2 ;;
        --output_dir)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --output_dir requires a <path>."
                print_help
                exit 1
            fi
            OUTPUT_DIR="$2";
            shift 2 ;;
        --max_batch_size)
            if [[ -z "$2" || "$2" == --* || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: --max_batch_size requires a positive integer."
                print_help
                exit 1
            fi
            MAX_BATCH_SIZE="$2";
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

# Check if required arguments are provided
if [[ -z "$CHECKPOINT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: both --checkpoint_dir and --output_dir are required."
    print_help
    exit 1
fi

echo "Building with the following parameters:"
echo "Model name: $MODEL_NAME"
echo "Checkpoint directory: $CHECKPOINT_DIR"
echo "Engine output directory: $OUTPUT_DIR"
echo "Engine PVC output directory: $PVC_OUTPUT_DIR"

# Please refer to:
# tensorrt_llm/plugin/plugin.py
# tensorrt_llm/commands/build.py
# Some default value, leave them in peace:
#   --remove_input_padding enable
#   --gpt_attention_plugin float16
#   --context_fmha enable
#   --gemm_plugin float16
#   --paged_kv_cache enable

# We need to modify the following parameters:
#   --checkpoint_dir, default None
#   --output_dir,     default engine_outputs
#   --max_batch_size, default 1
trtllm-build --checkpoint_dir "${CHECKPOINT_DIR}" \
             --output_dir "${OUTPUT_DIR}" \
             --max_batch_size "${MAX_BATCH_SIZE}"

echo "Building engines completed."