#!/bin/bash

set -e

# Setup ENV
## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct
## Source Code Path
TRT_LLM_DIR=/code/REServe/tensorrtllm_backend/tensorrt_llm

## Built engine directory
ENGINE_DIR=""
INPUT_TEXT=""
MAX_OUTPUT_LEN=50

print_help() {
    echo "Usage: $0 --input_text <text> --engine_dir <path> [--max_output_len <number>] [--help]"
    echo "Options:"
    echo "  --input_text      Required. Your input text."
    echo "  --engine_dir      Required. Directory containing the built engine."
    echo "  --max_output_len  Optional. Maximum output length. Default is 50."
    echo "  --help            Optional. Display this help message and exit."
}

# Parse command line arguments for --input_text, --engine_dir, and --max_output_len
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input_text)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --input_text requires a <text>."
                print_help
                exit 1
            fi
            INPUT_TEXT="$2";
            shift 2 ;;
        --engine_dir)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --engine_dir requires a <path>."
                print_help
                exit 1
            fi
            ENGINE_DIR="$2";
            shift 2 ;;
        --max_output_len)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --max_output_len requires a <number>."
                print_help
                exit 1
            fi
            MAX_OUTPUT_LEN="$2";
            shift 2 ;;
        --help)
            print_help
            exit 0 ;;
        *)
          echo "Unknown parameter passed: $1"
          print_help
          exit 1 ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$INPUT_TEXT" || -z "$ENGINE_DIR" ]]; then
    echo "Error: both --input_text and --engine_dir are required."
    print_help
    exit 1
fi

echo "Running inference with the following parameters:"
echo "Input text: $INPUT_TEXT"
echo "Max output length: $MAX_OUTPUT_LEN"
echo "Tokenizer directory: $MODEL_REPO_DIR"
echo "Engine directory: $ENGINE_DIR"

cd $TRT_LLM_DIR/examples

python3 run.py --input_text $INPUT_TEXT \
                  --max_output_len $MAX_OUTPUT_LEN \
                  --tokenizer_dir $MODEL_REPO_DIR \
                  --engine_dir $ENGINE_DIR