#!/bin/bash

# Upload Model Weights to PVC
kubectl apply -f model-store-pod.yaml
kubectl cp Meta-Llama-3-8B-Instruct model-store-pod:/mnt/models/Meta-Llama-3-8B-Instruct -c model-store -n llama
kubectl delete -f model-store-pod.yaml