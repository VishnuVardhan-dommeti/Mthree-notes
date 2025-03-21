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
