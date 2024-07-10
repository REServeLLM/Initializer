# Setup KServe with Serverless mode on Kubernetes

## Prerequisite
- Istio: https://istio.io/latest/docs/setup/install/istioctl/
```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.21.3 TARGET_ARCH=x86_64 sh -

cd istio-1.21.3/
export PATH=$PWD/bin:$PATH
istioctl install -y
```

WARN: If your cluster do not have `External LB`, you can use `NodePort` instead by changing type: LoadBalancer to type: NodePort in the `istio-ingressgateway` service.

## Quick Install
You can install KServe with Serverless mode on Kubernetes by running the `install.sh` script.
```bash
./install.sh
```

## Manual Install
You also can install KServe with Serverless mode on Kubernetes manually by following the steps below.

We use harbor registry in provided YAML files for connectivity, you can change the image registry to official or your own.
### Install Knative Serving
Please following Knative Official Website:
- https://knative.dev/docs/install/installing-istio/#using-istio-mtls-feature-with-knative
- https://kserve.github.io/website/0.13/get_started/first_isvc/#4-determine-the-ingress-ip-and-ports
```bash
kubectl label namespace knative-serving istio-injection=enabled --overwrite
kubectl apply -f kserve-setup/knative-istio-peer-auth.yaml
kubectl apply -f kserve-setup/serving-crds.yaml
kubectl apply -f kserve-setup/serving-core.yaml -n knative-serving
kubectl apply -f kserve-setup/net-istio.yaml
```

#### Install Cert Manager
```bash
kubectl apply -f kserve-setup/cert-manager.yaml
```

#### Configure No DNS
```bash
kubectl patch configmap/config-domain --namespace knative-serving  --type merge --patch '{"data":{"example.com":""}}'
```
### Install KServe
```bash
kubectl apply -f kserve-setup/kserve.yaml
kubectl apply -f kserve-setup/kserve-cluster-resources.yaml
```
#### Disable Top Level Virtual Service 
```bash
CONFIGMAP_NAME="inferenceservice-config"
NAMESPACE="kserve"

ORIGINAL_CONFIG=$(kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE -o yaml)
MODIFIED_CONFIG=$(echo "$ORIGINAL_CONFIG" | sed 's/"disableIstioVirtualHost": false/"disableIstioVirtualHost": true/')
echo "$MODIFIED_CONFIG" > temp.yaml
kubectl apply -f temp.yaml -n $NAMESPACE
rm temp.yaml
```

## Test Kserve
We also provide a simple sklearn-iris example for testing.
```bash
./test_simple.sh
```
