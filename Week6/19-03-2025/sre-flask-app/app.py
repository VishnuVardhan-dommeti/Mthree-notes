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
