# Initializer
Initializer for KServe Cluster with shell scripts and kubernetes YAML files.

## First LLM Serving with KServe
1. Install KServe, please check [KServe sub-directory](KServe/README.md).
2. Save Model Weights to PVC, please check [KServe Official Website](https://kserve.github.io/website/master/modelserving/storage/pvc/pvc/).
3. Build TensorRT-LLM Image with TensorRT-LLM release v0.10.0, please check [TRTLLM sub-directory](TRTLLM/README.md).
4. Convert Llama-3 huggingface weights to TensorRT weights, and build TensorRT engines.
5. Deploy Triton Inference Server with TensorRT-LLM model.
