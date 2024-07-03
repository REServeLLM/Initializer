#!/bin/bash

kubectl create ns kserve-test
kubectl label namespace kserve-test istio-injection=enabled --overwrite

kubectl apply -f kserve-simple-test/kserve-test-peer-auth.yaml
kubectl apply -f kserve-simple-test/kserve-test-sklearn-iris.yaml

export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

SERVICE_HOSTNAME=$(kubectl get inferenceservice sklearn-iris -n kserve-test -o jsonpath='{.status.url}' | cut -d "/" -f 3)

# Test Iris Service
curl -H "Host: ${SERVICE_HOSTNAME}" "http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/sklearn-iris"

# Test Iris Predictor
curl -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" \
--data-raw '{"instances": [[6.8, 2.8, 4.8, 1.4], [6.0, 3.4, 4.5, 1.6]]}' \
"http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/sklearn-iris:predict"