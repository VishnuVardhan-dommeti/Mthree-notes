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
