# Initializer
Initializer for KServe Cluster with shell scripts and kubernetes YAML files.

## First LLM Serving with KServe
1. Install KServe, please check [KServe sub-directory](KServe/README.md).
2. Convert Llama-3 huggingface weights to TensorRT weights, and build TensorRT engines.
3. Deploy Triton Inference Server with TensorRT-LLM model.
