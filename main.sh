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
PVC_OUTPUT_CKP_BASE_DIR=/mnt/models/checkpoints
PVC_OUTPUT_BASE_DIR=/mnt/models/engines
# Default values for TP and PP
TP_SIZE=1
PP_SIZE=1
GPU_SIZE=1
SUFFIX="-${GPU_SIZE}GPU-${TP_SIZE}TP-${PP_SIZE}PP"

PVC_OUTPUT_CKP_DIR="${PVC_OUTPUT_CKP_BASE_DIR}/${MODEL_NAME}${SUFFIX}"
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

# usage: is_dir_emtpy_or_not_exist <path>
is_dir_emtpy_or_not_exist() {
    if [ ! -d "$1" ] || [ -z "$(ls -A $1)" ]; then
        return 0
    else
        return 1
    fi
}

run_operations() {
    # Update params
    GPU_SIZE=$((TP_SIZE * PP_SIZE))
    SUFFIX="-${GPU_SIZE}GPU-${TP_SIZE}TP-${PP_SIZE}PP"

    OUTPUT_CKP_DIR="${BASE_CKP_DIR}/${MODEL_NAME}${SUFFIX}"

    PVC_OUTPUT_DIR="${PVC_OUTPUT_BASE_DIR}/${MODEL_NAME}${SUFFIX}"
    OUTPUT_DIR="${BASE_DIR}/${MODEL_NAME}${SUFFIX}"
    check_or_build_engines
    # TODO: call ./TIS/run.sh
}

check_or_build_engines() {
  echo "Try to locate container local engines: ${OUTPUT_DIR}"
  if is_dir_emtpy_or_not_exist "${OUTPUT_DIR}"; then
      echo "Container local engines not found, try to locate PVC engines: ${PVC_OUTPUT_DIR}"
      if is_dir_emtpy_or_not_exist "${PVC_OUTPUT_DIR}"; then
          echo "PVC engines not found, try to locate container local checkpoints: ${OUTPUT_CKP_DIR}"
          if is_dir_emtpy_or_not_exist "${OUTPUT_CKP_DIR}"; then
              echo "Container local checkpoints not found, try to locate PVC checkpoints: ${PVC_OUTPUT_CKP_DIR}"
              if is_dir_emtpy_or_not_exist "${PVC_OUTPUT_CKP_DIR}"; then
                  echo "PVC checkpoints not found, proceed to convert, save checkpoints and build, save engines"
                  echo "Convert huggingface checkpoints to container local checkpoints: ${OUTPUT_CKP_DIR}"
                  ./TRTLLM/convert_weight.sh --tp "${TP_SIZE}" --pp "${PP_SIZE}"
                  echo "Copy container local checkpoints to PVC checkpoints: ${PVC_OUTPUT_CKP_DIR}"
                  mkdir -p "${PVC_OUTPUT_CKP_DIR}"
                  cp -r "${OUTPUT_CKP_DIR}/"* "${PVC_OUTPUT_CKP_DIR}"
              else
                  echo "PVC checkpoints found, proceed to copy to container local checkpoints, build and save engines"
                  echo "Copy PVC checkpoints to container local checkpoints: ${OUTPUT_CKP_DIR}"
                  mkdir -p "${OUTPUT_CKP_DIR}"
                  cp -r "${PVC_OUTPUT_CKP_DIR}/"* "${OUTPUT_CKP_DIR}"
              fi
          else
              echo "Container local checkpoints found, proceed to save checkpoints, build and save engines"
              echo "Save container local checkpoints to PVC checkpoints: ${PVC_OUTPUT_CKP_DIR}"
              mkdir -p "${PVC_OUTPUT_CKP_DIR}"
              cp -r "${OUTPUT_CKP_DIR}/"* "${PVC_OUTPUT_CKP_DIR}"
          fi
          echo "Build engines to container local engines"
          ./TRTLLM/build_engine.sh --checkpoint_dir "${OUTPUT_CKP_DIR}" --output_dir "${OUTPUT_DIR}"
          echo "Save engines to PVC engines: ${PVC_OUTPUT_DIR}"
          mkdir -p "${PVC_OUTPUT_DIR}"
          cp -r "${OUTPUT_DIR}/"* "${PVC_OUTPUT_DIR}"
      else
          echo "PVC engines found, try to copy to container local engines: ${OUTPUT_DIR}"
          mkdir -p "${OUTPUT_DIR}"
          cp -r "$PVC_OUTPUT_DIR/"* "$OUTPUT_DIR"
      fi
  else
      echo "Engines already exist, skipping all conversion and building steps."
      echo "Robust to the case where container engines exist but PVC engines not exist"
      echo "Try to locate PVC engines: ${PVC_OUTPUT_DIR}"
      if is_dir_emtpy_or_not_exist "${PVC_OUTPUT_DIR}"; then
          echo "PVC engines not found, save container local engines to PVC engines: ${PVC_OUTPUT_DIR}"
          mkdir -p "${PVC_OUTPUT_DIR}"
          cp -r "${OUTPUT_DIR}/"* "${PVC_OUTPUT_DIR}"
      else
          echo "PVC engines found, everything is good"
      fi
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