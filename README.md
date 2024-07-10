 <!-- TOC -->
* [Initializer](#initializer)
  * [Project Structure](#project-structure)
  * [Environment](#environment)
  * [Basic Steps](#basic-steps)
    * [Build REServe Image](#build-reserve-image)
    * [Use REServe Image](#use-reserve-image)
    * [Convert and Build TensorRT-LLM Engines](#convert-and-build-tensorrt-llm-engines)
    * [Deploy Triton Inference Server](#deploy-triton-inference-server)
# Initializer
Initializer for KServe Cluster with shell scripts and kubernetes YAML files.

## Project Structure
- YAML: Contains the YAML files for deploying KServe, Triton Inference Server, and other Kubernetes resources.
- Shell: Contains the scripts for running the installation and test operation.
  - main.sh: calling convert_weight.sh, build_engine.sh, deploy_backend.sh, and test_serve.sh
  - KServe/install.sh: installing KServe in Kubernetes.
  - KServe/test_simple.sh: simple testing KServe's availability.
  - TIS/install.sh: installing Triton Inference Server Backend in Kubernetes.
  - TIS/run.sh: automatic execution at container startup.
  - TIS/test_serve.sh: simply testing inference service's availability. 
  - TRTLLM/upload_hf_model.sh: uploading huggingface weights to the PVC.
  - TRTLLM/convert_weight.sh: converting huggingface weights to formated TensorRT-LLM weights.
  - TRTLLM/build_engine.sh: building optimized TensorRT-LLM engines.
  - TRTLLM/test_inference.sh: testing TensorRT-LLM engines' availability.

## Environment
- Ubuntu: 22.04
- Kubernetes cluster: v1.26.9
- containerd: v1.7.2
- runc: 1.1.12
- cni: v1.5.1
- Istio: 1.21.3
- Knative: v1.12.4
- KServe: v0.13.0
- TensorRT-LLM: release v0.10.0
- Triton Inference Server: release v0.10.0
- Container Image: nvcr.io/nvidia/tritonserver:24.05-trtllm-python-py3
- Model: Llama-3-8B-Instruct/Llama-3-70B-Instruct

## Basic Steps
<a name="First LLM Serving with KServe"></a>
1. Install KServe, please check [KServe sub-directory](KServe/README.md).
2. Save Model Weights to PVC, please check [KServe Official Website](https://kserve.github.io/website/master/modelserving/storage/pvc/pvc/).
3. (Optional) Build REServe Image with TensorRT-LLM/Backend release v0.10.0, please check [Build REServe Image](#build-reserve-image).
4. Use REServe Image with TensorRT-LLM/Backend release v0.10.0, please check [Use REServe Image](#use-reserve-image).
5. Convert Llama-3 huggingface weights to TensorRT weights, and build TensorRT engines, please check [Convert and Build TensorRT-LLM Engines](#convert-and-build-tensorrt-llm-engines).
6. Deploy Triton Inference Server with TensorRT-LLM engines, please check [Deploy Triton Inference Server](#deploy-triton-inference-server).

### Build REServe Image
<a name="Build REServe Image"></a>
Build REServe Image with TensorRT-LLM/Backend release v0.10.0:
1. Clone the repository:
```bash
git clone https://github.com/REServeLLM/tensorrtllm_backend.git
# Update the submodules
cd tensorrtllm_backend
git lfs install
git submodule update --init --recursive
```

2. Build the TensorRT-LLM Backend image (contains the TensorRT-LLM and Backend components):
```bash
# Use the Dockerfile to build the backend in a container
# For Network Issue
DOCKER_BUILDKIT=1 docker build -t reserve-llm:latest \
                               --progress auto \
                               --network host \
                               -f dockerfile/Dockerfile.trt_llm_backend_network_proxy .
# For No Network Issue
DOCKER_BUILDKIT=1 docker build -t reserve-llm:latest \
                               --progress auto \
                               -f dockerfile/Dockerfile.trt_llm_backend .
```
3. Run the REServe image:
```bash
docker run -it -d --network=host --runtime=nvidia \
                  --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN \
                  --security-opt seccomp=unconfined \
                  --shm-size=16g --privileged --ulimit memlock=-1 \
                  --gpus=all --name=reserve \
                  reserve-llm:latest
                  
docker exec -it reserve /bin/bash
```

4. Copy the latest REServe source code to the REServe image:
```bash
docker cp REServe reserve:/code
```

5. Commit and push the REServe image to the registry:
```bash
docker commit reserve harbor.act.buaa.edu.cn/nvidia/reserve-llm:v20240709
```

### Use REServe Image
<a name="Use REServe Image"></a>
We provide pre-built REServe image, just pull image from registry:
```bash
docker pull harbor.act.buaa.edu.cn/nvidia/reserve-llm:v20240700

# Update the REServe Source Code
cd /code/REServe
cd Initializer
git pull
cd ../tensorrtllm_backend
git submodule update --init --recursive
git lfs install
```
Or you can use your own REServe image from the previous step.

### Convert and Build TensorRT-LLM Engines
<a name="Convert and Build TensorRT-LLM Engines"></a>
Operations in the REServe container:
```bash
cd /code/REServe/TRTLLM
./convert_engine.sh
./build_engine.sh
```

### Deploy Triton Inference Server
<a name="Deploy Triton Inference Server"></a>