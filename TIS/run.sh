#!/bin/bash

set -e

# Setup ENV
## Source Code Path
TIS_DIR=/code/REServe/tensorrtllm_backend
## Triton Model Repo Path
TRITON_MODEL_REPO=/code/REServe/tensorrtllm_backend/triton_model_repo
## HuggingFace Model in PVC Storage Path
MODEL_REPO_DIR=/mnt/models/models/Meta-Llama-3-8B-Instruct
## Triton Max Batch Size, must be the same as the parameter in building the engine
TRITON_MAX_BATCH_SIZE=8
## Output Path
OUTPUT_ENGINE_DIR=/workspace/engines

# Prepare Configs
cp $TIS_DIR/all_models/inflight_batcher_llm $TRITON_MODEL_REPO -r

python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/preprocessing/config.pbtxt tokenizer_dir:$MODEL_REPO_DIR,triton_max_batch_size:${TRITON_MAX_BATCH_SIZE},preprocessing_instance_count:1
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/postprocessing/config.pbtxt tokenizer_dir:$MODEL_REPO_DIR,triton_max_batch_size:${TRITON_MAX_BATCH_SIZE},postprocessing_instance_count:1
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/tensorrt_llm_bls/config.pbtxt triton_max_batch_size:${TRITON_MAX_BATCH_SIZE},decoupled_mode:False,bls_instance_count:1,accumulate_tokens:False
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/ensemble/config.pbtxt triton_max_batch_size:${TRITON_MAX_BATCH_SIZE}
python3 $TIS_DIR/tools/fill_template.py -i ${TRITON_MODEL_REPO}/tensorrt_llm/config.pbtxt triton_backend:tensorrtllm,triton_max_batch_size:${TRITON_MAX_BATCH_SIZE},decoupled_mode:False,max_beam_width:1,engine_dir:${OUTPUT_ENGINE_DIR},max_tokens_in_paged_kv_cache:1280,max_attention_window_size:1280,kv_cache_free_gpu_mem_fraction:0.5,exclude_input_in_output:True,enable_kv_cache_reuse:False,batching_strategy:inflight_fused_batching,max_queue_delay_microseconds:0

# Launch Triton Server
# pip install SentencePiece  # already installed
python3 $TIS_DIR/scripts/launch_triton_server.py --world_size 1 --model_repo=${TRITON_MODEL_REPO} --http_port=8080 --grpc_port=9000 --metrics_port=8002