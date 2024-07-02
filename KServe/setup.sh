#!/bin/bash

# Install Knative Serving
kubectl label namespace knative-serving istio-injection=enabled --overwrite
kubectl apply -f kserve-setup/knative-istio-peer-auth.yaml
kubectl apply -f kserve-setup/serving-crds.yaml
kubectl apply -f kserve-setup/serving-core.yaml -n knative-serving
kubectl apply -f kserve-setup/net-istio.yaml
kubectl apply -f kserve-setup/serving-default-domain.yaml
kubectl apply -f kserve-setup/cert-manager.yaml

# Install KServe with TensorRT-LLM Runtime
kubectl apply -f kserve-setup/kserve.yaml
kubectl apply -f kserve-setup/kserve-cluster-resources.yaml
kubectl apply -f kserve-setup/trtllm-clusterservingruntime.yaml

# Disable Top Level Virtual Service
CONFIGMAP_NAME="inferenceservice-config"
NAMESPACE="kserve"

ORIGINAL_CONFIG=$(kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE -o yaml)
MODIFIED_CONFIG=$(echo "$ORIGINAL_CONFIG" | sed 's/"disableIstioVirtualHost": false/"disableIstioVirtualHost": true/')
echo "$MODIFIED_CONFIG" > temp.yaml
kubectl apply -f temp.yaml -n $NAMESPACE
rm temp.yaml