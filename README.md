# Initializer
Initializer for KServe Cluster with shell scripts and kubernetes YAML files.

## Basic Steps
<a name="First LLM Serving with KServe"></a>
1. Install KServe, please check [KServe sub-directory](KServe/README.md).
2. Save Model Weights to PVC, please check [KServe Official Website](https://kserve.github.io/website/master/modelserving/storage/pvc/pvc/).
3. (Optional)Build REServe Image with TensorRT-LLM/Backend release v0.10.0, please check [Build REServe Image](#build-reserve-image).
4. Use REServe Image with TensorRT-LLM/Backend release v0.10.0, please check [Use REServe Image](#use-reserve-image).
5. Convert Llama-3 huggingface weights to TensorRT weights, and build TensorRT engines.
6. Deploy Triton Inference Server with TensorRT-LLM model.

## Build REServe Image
<a name="Build REServe Image"></a>



## Use REServe Image
<a name="Use REServe Image"></a>
We provide pre-built REServe image, just pull image from registry:
```bash
docker pull harbor.act.buaa.edu.cn/nvidia/reserve-llm:v20240708
```
