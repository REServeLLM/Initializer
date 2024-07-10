#!/bin/bash

# Setup ENV
## HuggingFace model name
MODEL_NAME=Meta-Llama-3-8B-Instruct
## Converted model checkpoint directory
CHECKPOINT_DIR=""
OUTPUT_DIR=""

print_help() {
    echo "Usage: $0 --checkpoint_dir <path> --output_dir <path>"
    echo "Options:"
    echo "  --checkpoint_dir  Required. Directory containing the converted model checkpoint."
    echo "  --output_dir      Required. Directory where the built engines will be saved."
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

echo "Start building TensorRT-LLM engines for model $MODEL_NAME from $CHECKPOINT_DIR to $OUTPUT_DIR."

# TODO: save the built engines to PVC storage
trtllm-build --checkpoint_dir $CHECKPOINT_DIR \
             --output_dir $OUTPUT_DIR \
             --gemm_plugin auto