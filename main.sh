#!/bin/bash

set -e

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")
# Change the working directory to the script's directory
cd "$SCRIPT_DIR"

## Output path
BASE_CKP_DIR=/workspace/checkpoints
BASE_DIR=/workspace/engines
## HuggingFace model name
MODEL_NAME=Meta-Llama-3-8B-Instruct
## HuggingFace model in PVC storage path
PVC_OUTPUT_BASE_DIR=/mnt/models/engines
# Default values for TP and PP
TP_SIZE=1
PP_SIZE=1
GPU_SIZE=1
SUFFIX="-${GPU_SIZE}GPU-${TP_SIZE}TP-${PP_SIZE}PP"

OUTPUT_CKP_DIR="${BASE_CKP_DIR}/${MODEL_NAME}${SUFFIX}"
PVC_OUTPUT_DIR="${PVC_OUTPUT_BASE_DIR}/${MODEL_NAME}${SUFFIX}"
OUTPUT_DIR="${BASE_DIR}/${MODEL_NAME}${SUFFIX}"

print_usage() {
    echo "Usage: $0 {run|test} [options]"
    echo "Options for run:"
    echo "  --tp <size>                Optional. Set the tensor parallel size, default 1"
    echo "  --pp <size>                Optional. Set the pipeline parallel size, default 1"
    echo "Options for test:"
    echo "  --input_text               Required. Your input text."
    echo "  --max_output_len           Optional. Maximum output length. Default is 50."
}

run_operations() {
    # Update params
    GPU_SIZE=$((TP_SIZE * PP_SIZE))
    SUFFIX="-${GPU_SIZE}GPU-${TP_SIZE}TP-${PP_SIZE}PP"

    OUTPUT_CKP_DIR="${BASE_CKP_DIR}/${MODEL_NAME}${SUFFIX}"

    PVC_OUTPUT_DIR="${PVC_OUTPUT_BASE_DIR}/${MODEL_NAME}${SUFFIX}"
    OUTPUT_DIR="${BASE_DIR}/${MODEL_NAME}${SUFFIX}"
    check_and_copy_engines
    # Additional run logic here
}

check_and_copy_engines() {
  if [ -d "$PVC_OUTPUT_DIR" ]; then
      echo "Engines already exist, skipping conversion and building."
      echo "Loading engines from PVC storage: ${PVC_OUTPUT_DIR} to ${OUTPUT_DIR}"
      if [ -d "$OUTPUT_DIR" ]; then
          # Ensure the target directory exists
          mkdir -p "$OUTPUT_DIR"
      else
          echo "Error: output directory does not exist and could not be created."
          exit 1
      fi
      cp -r "${PVC_OUTPUT_DIR}/"* "${OUTPUT_DIR}/"
  else
      echo "Engines not found, proceeding with conversion and building."
      # Call the necessary scripts
      ./TRTLLM/convert_weight.sh --tp "${TP_SIZE}" --pp "${PP_SIZE}"
      ./TRTLLM/build_engine.sh --checkpoint_dir "${OUTPUT_CKP_DIR}" --output_dir "${OUTPUT_DIR}"
      if [ -d "$PVC_OUTPUT_DIR" ]; then
          # Ensure the target directory exists
          mkdir -p "$PVC_OUTPUT_DIR"
      else
          echo "Error: PVC output directory does not exist and could not be created."
          exit 1
      fi
      cp -r "$OUTPUT_DIR/"* "$PVC_OUTPUT_DIR/"
  fi
}

test_inference() {
    ./TRTLLM/test_serve.sh --input_text "${INPUT_TEXT}" --max_output_len "${MAX_OUTPUT_LEN}"
    # Additional test logic here
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi
OPERATION=$1; shift # Remove the operation from the arguments list

case "$OPERATION" in
    run)
        while [ $# -gt 0 ]; do
            case "$1" in
                --tp) TP_SIZE="$2"; shift 2;;
                --pp) PP_SIZE="$2"; shift 2;;
                --) shift; break;;
                *) break;;
            esac
        done
        run_operations
        ;;
    test)
        while [ $# -gt 0 ]; do
            case "$1" in
                --input_text) INPUT_TEXT="$2"; shift 2;;
                --max_output_len) MAX_OUTPUT_LEN="$2"; shift 2;;
                --) shift; break;;
                *) break;;
            esac
        done
        test_inference
        ;;
    *)
        print_usage
        exit 1
        ;;
esac