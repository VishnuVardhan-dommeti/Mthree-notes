#!/bin/bash
set -e

echo "Setting up minimal monitoring stack..."

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories if they don't exist
if ! helm repo list | grep -q "prometheus-community"; then
  echo "Adding Prometheus Helm repository..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
fi

if ! helm repo list | grep -q "grafana"; then
  echo "Adding Grafana Helm repository..."
  helm repo add grafana https://grafana.github.io/helm-charts
fi

helm repo update

# Install a minimal Prometheus (without many components to save resources)
echo "Installing Prometheus (lightweight configuration)..."
cat > prometheus-values.yaml << 'EOPROMETHEUS'
alertmanager:
  enabled: false
pushgateway:
  enabled: false
nodeExporter:
  enabled: false
server:
  persistentVolume:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 200m
      memory: 512Mi
EOPROMETHEUS

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait

echo "Waiting for Prometheus to be fully ready..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus-server -n monitoring

# Install a lightweight version of Loki
echo "Installing Loki (lightweight configuration)..."
cat > loki-values.yaml << 'EOLOKI'
loki:
  persistence:
    enabled: false
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
promtail:
  resources:
    requests:
      cpu: 20m
      memory: 64Mi
    limits:
      cpu: 50m
      memory: 128Mi
  config:
    snippets:
      pipelineStages:
        - docker: {}
EOLOKI

helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --values loki-values.yaml \
  --wait

echo "Waiting for Loki to be fully ready..."
kubectl rollout status statefulset/loki -n monitoring --timeout=120s

# Install Grafana with minimal resources
echo "Installing Grafana (lightweight configuration)..."
cat > grafana-values.yaml << 'EOGRAFANA'
persistence:
  enabled: false
resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 100m
    memory: 256Mi
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.monitoring.svc.cluster.local
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://loki.monitoring.svc.cluster.local:3100
      access: proxy
adminUser: admin
adminPassword: admin
EOGRAFANA

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana-values.yaml \
  --wait

echo "Waiting for Grafana to be fully ready..."
kubectl rollout status deployment/grafana -n monitoring --timeout=120s

echo "Monitoring stack has been set up successfully!"
echo "Access Grafana:"
echo "  kubectl port-forward svc/grafana 3000:80 -n monitoring"
echo "  Default credentials: admin / admin"
