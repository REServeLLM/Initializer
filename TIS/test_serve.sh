#!/bin/bash

# Test the model serving on one terminal of kubernetes nodes

export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

SERVICE_HOSTNAME=$(kubectl get inferenceservice llama-3-8b -n llama -o jsonpath='{.status.url}' | cut -d "/" -f 3)

echo $INGRESS_HOST
echo $INGRESS_PORT
echo $SERVICE_HOSTNAME

# Test in container
curl "http://localhost:8080/v2/models/ensemble/generate" -d '{"text_input": "What is machine learning?", "max_tokens": 20, "bad_words": "", "stop_words": "", "pad_id": 2, "end_id": 2}'

# Test in cluster
curl -H "Host: ${SERVICE_HOSTNAME}" "http://${INGRESS_HOST}:${INGRESS_PORT}/v2/models/ensemble/generate" -d '{"text_input": "What is machine learning?", "max_tokens": 20, "bad_words": "", "stop_words": "", "pad_id": 2, "end_id": 2}'
