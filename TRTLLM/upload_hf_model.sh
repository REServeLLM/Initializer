#!/bin/bash

# Upload Model Weights to PVC
kubectl apply -f config/model-store-pod.yaml
kubectl cp models/Meta-Llama-3-8B-Instruct model-store-pod:/mnt/models/Meta-Llama-3-8B-Instruct -c model-store -n llama
kubectl delete -f config/model-store-pod.yaml