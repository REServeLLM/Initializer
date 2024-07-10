#!/bin/bash

set -e

kubectl apply -f config/trtllm-clusterservingruntime.yaml
kubectl apply -f config/trtllm-istio-peerauthentication.yaml

# You need replace 'llama' with your own [namespace]
kubectl label namespace llama istio-injection=enabled --overwrite




