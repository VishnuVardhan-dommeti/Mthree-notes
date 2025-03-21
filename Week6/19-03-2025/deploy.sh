#!/bin/bash

# Exit on error
set -e

echo "============================================================"
echo "  LIGHTWEIGHT SRE MONITORING SETUP FOR MINIKUBE/WSL"
echo "============================================================"
echo "This script will:"
echo "  1. Reset minikube for a clean environment"
echo "  2. Create a lightweight Python Flask API with SRE instrumentation"
echo "  3. Deploy it to Kubernetes with appropriate waits between steps"
echo "  4. Set up minimal but effective monitoring"
echo "============================================================"

# Function to check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: $1 is required but not installed."
    exit 1
  fi
}

# Function to wait with a countdown
wait_with_message() {
  local seconds=$1
  local message=$2
  
  echo -n "$message "
  for (( i=$seconds; i>0; i-- )); do
    echo -n "$i... "
    sleep 1
  done
  echo "Done!"
}

# Check for required commands
echo "Checking prerequisites..."
check_command kubectl
check_command docker
check_command minikube
check_command helm

# Step 1: Clean up any existing setup
echo "Cleaning up previous setup if it exists..."
minikube delete || true
wait_with_message 3 "Waiting for minikube to fully shut down..."

# Step 2: Start minikube with appropriate resources
echo "Starting minikube with optimized settings for WSL..."
minikube start --driver=docker --cpus=2 --memory=3072 --disk-size=10g

# Verify minikube is running
echo "Verifying minikube status..."
minikube status
echo "Kubernetes version:"
kubectl version 

# Step 3: Create a project directory
echo "Creating project directory..."
mkdir -p sre-flask-app
cd sre-flask-app

# Step 4: Create a smaller, optimized Python Flask application
echo "Creating Python Flask application with SRE instrumentation..."

# Create main app file
cat > app.py << 'EOF'
import os
import time
import random
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from prometheus_client import make_wsgi_app

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s - request_id=%(request_id)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# Initialize Flask app
app = Flask(__name__)

# Add Prometheus WSGI middleware
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

# Define Prometheus metrics
REQUEST_COUNT = Counter(
    'app_request_count', 
    'Application Request Count',
    ['endpoint', 'method', 'http_status']
)
REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds', 
    'Application Request Latency',
    ['endpoint', 'method'],
    buckets=[0.01, 0.05, 0.1, 0.5, 1, 2, 5]
)
ERROR_COUNTER = Counter(
    'app_error_count',
    'Application Error Count',
    ['error_type', 'endpoint']
)
ACTIVE_REQUESTS = Gauge(
    'app_active_requests',
    'Active Requests Currently Being Processed'
)

# Sample database - kept small for memory efficiency
users_db = [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"}
]

# Simulated database query with variable latency
def simulate_db_query(query_type="read"):
    # Simulate different query times based on query type
    time_ranges = {
        "read": (0.001, 0.05),
        "write": (0.005, 0.1),
        "complex": (0.01, 0.2)
    }
    
    min_time, max_time = time_ranges.get(query_type, (0.001, 0.05))
    
    # Occasionally simulate slow queries
    if random.random() < 0.05:  # 5% chance
        query_time = random.uniform(max_time, max_time * 4)
        app.logger.warning(
            f"Slow {query_type} query detected, took {query_time:.4f}s",
            extra={"request_id": getattr(request, 'request_id', 'unknown')}
        )
    else:
        query_time = random.uniform(min_time, max_time)
    
    time.sleep(query_time)
    return query_time

# Request logging middleware
@app.before_request
def before_request():
    request.start_time = time.time()
    ACTIVE_REQUESTS.inc()
    
    # Add request ID for tracking
    request.request_id = str(random.randint(1000, 9999))

@app.after_request
def after_request(response):
    ACTIVE_REQUESTS.dec()
    
    # Calculate request processing time
    request_time = time.time() - request.start_time
    
    # Record request latency
    REQUEST_LATENCY.labels(
        endpoint=request.path,
        method=request.method
    ).observe(request_time)
    
    # Record request count
    REQUEST_COUNT.labels(
        endpoint=request.path,
        method=request.method,
        http_status=response.status_code
    ).inc()
    
    # Log request details
    app.logger.info(
        f"Processed {request.method} {request.path} in {request_time:.4f}s with status {response.status_code}",
        extra={"request_id": getattr(request, 'request_id', 'unknown')}
    )
    
    return response

# Health check endpoint (for Kubernetes probes)
@app.route('/health/liveness')
def liveness_check():
    # Simple liveness check - just verify the app is running
    return jsonify({"status": "alive", "timestamp": datetime.now().isoformat()}), 200

@app.route('/health/readiness')
def readiness_check():
    # More complex readiness check - verify dependencies
    try:
        simulate_db_query("read")
        return jsonify({"status": "ready", "checks": {"database": "connected"}}), 200
    except Exception as e:
        ERROR_COUNTER.labels(error_type="dependency_failure", endpoint="/health/readiness").inc()
        return jsonify({"status": "not ready", "checks": {"database": str(e)}}), 503

# API endpoints
@app.route('/')
def root():
    return render_template('index.html', version="1.0.0")

@app.route('/api/users')
def get_users():
    # Simulate DB query
    simulate_db_query("read")
    
    # Occasionally simulate an error
    if random.random() < 0.02:  # 2% error rate
        ERROR_COUNTER.labels(error_type="database_error", endpoint="/api/users").inc()
        app.logger.error(
            "Database error occurred: Failed to retrieve users",
            extra={"request_id": getattr(request, 'request_id', 'unknown')}
        )
        return jsonify({"error": "Database error"}), 500
    
    return jsonify(users_db)

@app.route('/api/echo', methods=['POST'])
def echo():
    # Echo back the JSON received
    data = request.get_json(silent=True)
    if data is None:
        ERROR_COUNTER.labels(error_type="invalid_input", endpoint="/api/echo").inc()
        return jsonify({"error": "Invalid JSON"}), 400
    
    # Simulate a write operation
    simulate_db_query("write")
    
    return jsonify(data)

@app.route('/api/error')
def simulate_error():
    # Deliberately cause an error for testing
    ERROR_COUNTER.labels(error_type="simulated_error", endpoint="/api/error").inc()
    
    error_type = request.args.get('type', 'server')
    
    if error_type == 'client':
        app.logger.warning(
            "Client error simulated",
            extra={"request_id": getattr(request, 'request_id', 'unknown')}
        )
        return jsonify({"error": "Bad Request Simulation"}), 400
    else:
        app.logger.error(
            "Server error simulated",
            extra={"request_id": getattr(request, 'request_id', 'unknown')}
        )
        return jsonify({"error": "Internal Server Error Simulation"}), 500

@app.route('/api/slow')
def slow_response():
    # Simulate a slow API response
    delay = min(float(request.args.get('delay', 1)), 5)  # Cap at 5 seconds for resource efficiency
    
    app.logger.info(
        f"Processing slow request with {delay}s delay",
        extra={"request_id": getattr(request, 'request_id', 'unknown')}
    )
    
    # Simulate a complex query
    simulate_db_query("complex")
    
    # Additional delay
    time.sleep(delay)
    
    return jsonify({"message": f"Slow response completed after {delay} seconds"})

# Run the application
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.2.3
Werkzeug==2.2.3
prometheus-client==0.16.0
gunicorn==20.1.0
EOF

# Create templates directory and index.html
mkdir -p templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SRE Demo API Documentation</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="header">
        <h1>SRE Demo API</h1>
        <p>Version {{ version }}</p>
    </div>

    <div class="container">
        <div class="endpoints-grid">
            <!-- Users Endpoint -->
            <div class="endpoint-card">
                <h3>Get Users</h3>
                <span class="method get">GET</span>
                <div class="url">/api/users</div>
                <p>Retrieve a list of users from the database.</p>
                <div class="response">
{
    "users": [
        {"id": 1, "name": "Alice", "email": "alice@example.com"},
        {"id": 2, "name": "Bob", "email": "bob@example.com"}
    ]
}</div>
                <span class="status-badge success">200 OK</span>
            </div>

            <!-- Echo Endpoint -->
            <div class="endpoint-card">
                <h3>Echo Request</h3>
                <span class="method post">POST</span>
                <div class="url">/api/echo</div>
                <p>Echo back the JSON data received in the request body.</p>
                <div class="response">
{
    "message": "Your request data will be echoed back"
}</div>
                <span class="status-badge success">200 OK</span>
            </div>

            <!-- Error Endpoint -->
            <div class="endpoint-card">
                <h3>Simulate Error</h3>
                <span class="method get">GET</span>
                <div class="url">/api/error</div>
                <p>Simulate different types of errors for testing.</p>
                <div class="response">
{
    "error": "Error message will vary based on type"
}</div>
                <span class="status-badge error">400/500</span>
            </div>

            <!-- Slow Endpoint -->
            <div class="endpoint-card">
                <h3>Slow Response</h3>
                <span class="method get">GET</span>
                <div class="url">/api/slow?delay=1</div>
                <p>Simulate a slow API response with configurable delay.</p>
                <div class="response">
{
    "message": "Slow response completed after X seconds"
}</div>
                <span class="status-badge warning">200 OK</span>
            </div>

            <!-- Health Check Endpoints -->
            <div class="endpoint-card">
                <h3>Health Checks</h3>
                <span class="method get">GET</span>
                <div class="url">/health/liveness</div>
                <p>Basic health check endpoint.</p>
                <div class="response">
{
    "status": "alive",
    "timestamp": "2024-03-19T04:44:39"
}</div>
                <span class="status-badge success">200 OK</span>
            </div>

            <div class="endpoint-card">
                <h3>Readiness Check</h3>
                <span class="method get">GET</span>
                <div class="url">/health/readiness</div>
                <p>Detailed readiness check including dependencies.</p>
                <div class="response">
{
    "status": "ready",
    "checks": {
        "database": "connected"
    }
}</div>
                <span class="status-badge success">200 OK</span>
            </div>

            <!-- Metrics Endpoint -->
            <div class="endpoint-card">
                <h3>Prometheus Metrics</h3>
                <span class="method get">GET</span>
                <div class="url">/metrics</div>
                <p>Expose Prometheus metrics for monitoring.</p>
                <div class="response">
# HELP app_request_count Application Request Count
# TYPE app_request_count counter
...</div>
                <span class="status-badge success">200 OK</span>
            </div>
        </div>

        <div class="metrics-section">
            <h2>Available Metrics</h2>
            <p>The following metrics are available for monitoring:</p>
            <ul>
                <li><strong>app_request_count</strong> - Total number of requests by endpoint, method, and status</li>
                <li><strong>app_request_latency_seconds</strong> - Request latency histogram by endpoint and method</li>
                <li><strong>app_error_count</strong> - Number of errors by type and endpoint</li>
                <li><strong>app_active_requests</strong> - Current number of active requests being processed</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create static/css directory and style.css
mkdir -p static/css
cat > static/css/style.css << 'EOF'
:root {
    --primary-color: #2c3e50;
    --secondary-color: #3498db;
    --accent-color: #e74c3c;
    --background-color: #f5f6fa;
    --text-color: #2c3e50;
    --card-background: #ffffff;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
    background-color: var(--background-color);
    color: var(--text-color);
    line-height: 1.6;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}

.header {
    background-color: var(--primary-color);
    color: white;
    padding: 2rem 0;
    text-align: center;
    margin-bottom: 2rem;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.header h1 {
    font-size: 2.5rem;
    margin-bottom: 0.5rem;
}

.header p {
    font-size: 1.1rem;
    opacity: 0.9;
}

.endpoints-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1.5rem;
    margin-top: 2rem;
}

.endpoint-card {
    background-color: var(--card-background);
    border-radius: 10px;
    padding: 1.5rem;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.endpoint-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.endpoint-card h3 {
    color: var(--secondary-color);
    margin-bottom: 1rem;
    font-size: 1.2rem;
}

.endpoint-card p {
    color: #666;
    margin-bottom: 1rem;
}

.endpoint-card .method {
    display: inline-block;
    padding: 0.3rem 0.8rem;
    border-radius: 20px;
    font-size: 0.9rem;
    font-weight: bold;
    margin-bottom: 0.5rem;
}

.method.get {
    background-color: #2ecc71;
    color: white;
}

.method.post {
    background-color: #3498db;
    color: white;
}

.method.put {
    background-color: #f1c40f;
    color: white;
}

.method.delete {
    background-color: #e74c3c;
    color: white;
}

.endpoint-card .url {
    background-color: #f8f9fa;
    padding: 0.5rem;
    border-radius: 5px;
    font-family: monospace;
    margin-bottom: 1rem;
    word-break: break-all;
}

.endpoint-card .response {
    background-color: #f8f9fa;
    padding: 1rem;
    border-radius: 5px;
    font-family: monospace;
    font-size: 0.9rem;
    white-space: pre-wrap;
}

.metrics-section {
    background-color: var(--card-background);
    border-radius: 10px;
    padding: 1.5rem;
    margin-top: 2rem;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.metrics-section h2 {
    color: var(--secondary-color);
    margin-bottom: 1rem;
}

.metrics-section pre {
    background-color: #f8f9fa;
    padding: 1rem;
    border-radius: 5px;
    overflow-x: auto;
    font-family: monospace;
    font-size: 0.9rem;
}

.status-badge {
    display: inline-block;
    padding: 0.3rem 0.8rem;
    border-radius: 20px;
    font-size: 0.9rem;
    font-weight: bold;
    margin-left: 0.5rem;
}

.status-badge.success {
    background-color: #2ecc71;
    color: white;
}

.status-badge.error {
    background-color: #e74c3c;
    color: white;
}

.status-badge.warning {
    background-color: #f1c40f;
    color: white;
}

@media (max-width: 768px) {
    .container {
        padding: 1rem;
    }
    
    .header {
        padding: 1.5rem 0;
    }
    
    .header h1 {
        font-size: 2rem;
    }
    
    .endpoints-grid {
        grid-template-columns: 1fr;
    }
}
EOF

# Create Dockerfile optimized for size
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code, templates, and static files
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Set environment variables
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/health/liveness || exit 1

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "2", "app:app"]

EXPOSE 8080
EOF

# Step 5: Create minimal Kubernetes manifests
echo "Creating Kubernetes manifests..."

# Create namespace
cat > k8s-namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: sre-demo
EOF

# Create ConfigMap for app configuration
cat > k8s-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: sre-flask-app-config
  namespace: sre-demo
data:
  LOG_LEVEL: "INFO"
EOF

# Create Service
cat > k8s-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: sre-flask-app
  namespace: sre-demo
  labels:
    app: sre-flask-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "8080"
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: http
  selector:
    app: sre-flask-app
EOF

# Create Deployment with minimal resource requirements
cat > k8s-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sre-flask-app
  namespace: sre-demo
  labels:
    app: sre-flask-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sre-flask-app
  template:
    metadata:
      labels:
        app: sre-flask-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: sre-flask-app
        image: sre-flask-app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: sre-flask-app-config
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
        livenessProbe:
          httpGet:
            path: /health/liveness
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
          timeoutSeconds: 3
        readinessProbe:
          httpGet:
            path: /health/readiness
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 2
EOF

# Step 6: Create a lightweight monitoring setup script
echo "Creating monitoring setup script..."

cat > setup-monitoring.sh << 'EOF'
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
EOF

chmod +x setup-monitoring.sh

# Step 7: Create a simple load testing script (very lightweight)
echo "Creating load testing script..."

cat > load-test.sh << 'EOF'
#!/bin/bash

# Simple load test script that uses minimal resources
API_URL="http://$(kubectl get svc -n sre-demo sre-flask-app -o jsonpath='{.spec.clusterIP}')"

echo "Starting minimal load test against $API_URL"
echo "Press Ctrl+C to stop..."

# Function to make a request
make_request() {
  local endpoint="$1"
  local method="$2"
  local data="$3"
  
  if [ "$method" = "POST" ]; then
    curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL$endpoint" > /dev/null
  else
    curl -s "$API_URL$endpoint" > /dev/null
  fi
  
  echo "$(date +%H:%M:%S) - Made $method request to $endpoint"
}

# Main loop - very lightweight to avoid resource contention
while true; do
  # Choose a random endpoint
  endpoints=("/api/users" "/api/error" "/api/slow")
  endpoint=${endpoints[$RANDOM % ${#endpoints[@]}]}
  
  case "$endpoint" in
    "/api/echo")
      make_request "$endpoint" "POST" '{"test":"data"}'
      ;;
    "/api/error")
      make_request "$endpoint" "GET"
      ;;
    "/api/slow")
      make_request "$endpoint?delay=0.5" "GET"  # Short delay to avoid resource issues
      ;;
    *)
      make_request "$endpoint" "GET"
      ;;
  esac
  
  # Sleep longer between requests to use fewer resources
  sleep 3
done
EOF

chmod +x load-test.sh

# Step 8: Create instruction file for dashboards
echo "Creating Grafana dashboard instructions..."

cat > grafana-dashboard-instructions.md << 'EOF'
# SRE Flask App Grafana Dashboard Setup Instructions

This guide will help you create monitoring dashboards in Grafana to visualize the SRE metrics from your Flask application.

## Basic SRE Dashboard

### Step 1: Create a New Dashboard

1. Click the "+" icon in the left sidebar
2. Select "Dashboard" from the dropdown menu
3. Click "Add new panel"

### Step 2: Request Rate Panel (Traffic)

1. In the query editor, select "Prometheus" as the data source
2. Enter this PromQL query:
   ```
   sum(rate(app_request_count{namespace="sre-demo"}[1m])) by (endpoint)
   ```
3. Set visualization to "Time series"
4. Title: "Request Rate by Endpoint"
5. Under "Standard options", set unit to "requests/sec"
6. Click "Apply"

### Step 3: Error Rate Panel (Errors)

1. Click "Add panel" 
2. Select "Prometheus" as the data source
3. Enter this query:
   ```
   sum(rate(app_request_count{namespace="sre-demo", http_status=~"5.."}[1m])) / sum(rate(app_request_count{namespace="sre-demo"}[1m])) * 100
   ```
4. Set visualization to "Stat"
5. Title: "Error Rate (%)"
6. Under "Standard options", set unit to "Percent (0-100)"
7. Add thresholds: 0-1 green, 1-5 orange, 5-100 red
8. Click "Apply"

### Step 4: Latency Panel (Latency)

1. Click "Add panel"
2. Select "Prometheus" as the data source
3. Enter this query:
   ```
   histogram_quantile(0.95, sum(rate(app_request_latency_seconds_bucket{namespace="sre-demo"}[5m])) by (le, endpoint))
   ```
4. Set visualization to "Time series"
5. Title: "95th Percentile Latency by Endpoint"
6. Under "Standard options", set unit to "seconds"
7. Click "Apply"

### Step 5: Active Requests Panel (Saturation)

1. Click "Add panel"
2. Select "Prometheus" as the data source
3. Enter this query:
   ```
   app_active_requests{namespace="sre-demo"}
   ```
4. Set visualization to "Stat"
5. Title: "Active Requests"
6. Click "Apply"

### Step 6: Save the Dashboard

1. Click the save icon in the top-right corner
2. Name the dashboard "SRE Basic Dashboard"
3. Click "Save"

## Log Analysis Dashboard

### Step 1: Create a New Dashboard

1. Click the "+" icon in the left sidebar
2. Select "Dashboard" from the dropdown
3. Click "Add new panel"

### Step 2: Create Log Panel

1. Select "Loki" as the data source
2. Enter this LogQL query:
   ```
   {namespace="sre-demo"}
   ```
3. Set visualization to "Logs"
4. Title: "Application Logs"
5. Enable "Show time" under Options
6. Click "Apply"

### Step 3: Create Error Logs Panel

1. Click "Add panel"
2. Select "Loki" as the data source
3. Enter this query:
   ```
   {namespace="sre-demo"} |= "error"
   ```
4. Set visualization to "Logs"
5. Title: "Error Logs"
6. Click "Apply"

### Step 4: Create Log Volume Panel

1. Click "Add panel"
2. Select "Loki" as the data source
3. Enter this query:
   ```
   sum(count_over_time({namespace="sre-demo"}[1m]))
   ```
4. Set visualization to "Time series"
5. Title: "Log Volume"
6. Click "Apply"

### Step 5: Save the Dashboard

1. Click the save icon in the top-right corner
2. Name the dashboard "Log Analysis"
3. Click "Save"

## Creating Dashboard Variables (Optional)

To make your dashboards more flexible:

1. Click the gear icon in the top-right corner
2. Select "Variables" from the left menu
3. Click "Add variable"
4. Configure a namespace variable:
   - Name: namespace
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(kube_namespace_labels, namespace)`
5. Click "Add" then "Save"
6. Update your queries to use the variable:
   - Change `namespace="sre-demo"` to `namespace="$namespace"`
EOF

# Step 9: Build the Docker image with minikube's Docker environment
echo "Building Docker image in minikube's Docker environment..."
eval $(minikube docker-env)
docker build -t sre-flask-app:latest .

# Step 10: Deploy to Kubernetes
echo "Deploying application to Kubernetes..."
kubectl apply -f k8s-namespace.yaml
kubectl apply -f k8s-configmap.yaml
kubectl apply -f k8s-service.yaml
kubectl apply -f k8s-deployment.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/sre-flask-app -n sre-demo --timeout=120s

echo "Application deployed successfully!"

# Step 11: Set up monitoring with proper waits
echo "Setting up monitoring stack..."
./setup-monitoring.sh

# Step 12: Start load generator in background
echo "Starting minimal load generator in background..."
./load-test.sh > load-test.log 2>&1 &
LOAD_TEST_PID=$!
echo $LOAD_TEST_PID > load-test.pid
echo "Load generator started with PID $LOAD_TEST_PID. Logs in load-test.log"

# Step 13: Set up port forwarding for Grafana
echo "Setting up port forwarding for Grafana..."
kubectl port-forward svc/grafana 3000:80 -n monitoring &
GRAFANA_PID=$!
echo $GRAFANA_PID > grafana.pid
echo "Grafana port-forwarding started with PID $GRAFANA_PID"

echo "==================================================================="
echo "SETUP COMPLETE!"
echo "==================================================================="
echo "Your SRE Flask App and monitoring are now running!"
echo ""
echo "Access your application:"
echo "  kubectl port-forward svc/sre-flask-app 8080:80 -n sre-demo"
echo ""
echo "Access Grafana:"
echo "  Grafana URL: http://localhost:3000"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Follow the instructions in grafana-dashboard-instructions.md"
echo "to set up your Grafana dashboards."
echo ""
echo "To clean up all resources, run:"
echo "  kill \$(cat load-test.pid)"
echo "  kill \$(cat grafana.pid)"
echo "  kubectl delete namespace sre-demo"
echo "  kubectl delete namespace monitoring"
echo "  minikube stop"
echo "==================================================================="


