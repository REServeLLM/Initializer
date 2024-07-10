#!/bin/bash

set -e

# Add TensorRT-LLM Runtime CRD in K8s
kubectl apply -f config/trtllm-clusterservingruntime.yaml
# Set Istio Ingress Authentication
kubectl apply -f config/trtllm-istio-peerauthentication.yaml

# You need replace 'llama' with your own [namespace]
kubectl label namespace llama istio-injection=enabled --overwrite
