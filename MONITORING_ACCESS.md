# 📊 Prometheus & Grafana Access Guide

## 🚀 Quick Setup (Already Done!)

The monitoring stack has been installed with:
- **Prometheus** - Metrics collection and alerting
- **Grafana** - Dashboards and visualization  
- **Alertmanager** - Alert management
- **Node Exporter** - System metrics
- **Kube State Metrics** - Kubernetes metrics

## 🔑 Access Credentials

### Grafana Login:
- **Username**: `admin`
- **Password**: `prom-operator`

## 🌐 How to Access the Dashboards

### Method 1: Port Forwarding (Recommended for Local)

#### Access Grafana:
```bash
# Get the Grafana pod name and port-forward
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kps" -o jsonpath="{.metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000

# Or use the service directly:
kubectl --namespace monitoring port-forward svc/kps-grafana 3000:80
```
**Then open**: http://localhost:3000
- Username: `admin`
- Password: `prom-operator`

#### Access Prometheus:
```bash
kubectl --namespace monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090
```
**Then open**: http://localhost:9090

#### Access Alertmanager:
```bash
kubectl --namespace monitoring port-forward svc/kps-kube-prometheus-stack-alertmanager 9093:9093
```
**Then open**: http://localhost:9093

### Method 2: Using kubectl proxy
```bash
# Start kubectl proxy
kubectl proxy

# Access via proxy URLs:
# Grafana: http://localhost:8001/api/v1/namespaces/monitoring/services/kps-grafana:80/proxy/
# Prometheus: http://localhost:8001/api/v1/namespaces/monitoring/services/kps-kube-prometheus-stack-prometheus:9090/proxy/
```

### Method 3: LoadBalancer/NodePort (for cloud clusters)
```bash
# Change service types to LoadBalancer or NodePort
kubectl patch svc kps-grafana -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch svc kps-kube-prometheus-stack-prometheus -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'

# Get external IPs
kubectl get svc -n monitoring
```

## 📈 What You'll See in Grafana

### Pre-built Dashboards:
1. **Kubernetes / Compute Resources / Cluster** - Overall cluster health
2. **Kubernetes / Compute Resources / Namespace (Pods)** - Pod-level metrics
3. **Kubernetes / Compute Resources / Pod** - Individual pod details
4. **Node Exporter / Nodes** - Server metrics
5. **Kubernetes / API server** - API server performance

### Key Metrics to Monitor:
- **CPU Usage**: Pod and node CPU utilization
- **Memory Usage**: Memory consumption and limits
- **Network I/O**: Traffic between services
- **Pod Restarts**: Application stability
- **Request Rate**: API call frequency
- **Response Time**: Latency metrics

## 🚨 Custom TechCommerce Alerts

Your custom alerts are now active and will trigger on:

1. **High Pod Restarts**: >3 restarts in 10 minutes
2. **High API Response Time**: >2s 95th percentile for 5 minutes  
3. **High Error Rate**: >5% 5xx responses for 5 minutes
4. **High Disk Usage**: >85% for 10 minutes

### View Alerts in:
- **Prometheus**: http://localhost:9090/alerts
- **Alertmanager**: http://localhost:9093
- **Grafana**: Alerting → Alert Rules

## 🎯 How to Deploy Your Apps for Monitoring

### Deploy TechCommerce to see metrics:
```bash
# Deploy staging environment
kubectl apply -k k8s/overlays/staging

# Check if pods are running
kubectl -n techcommerce-staging get pods

# Generate some traffic to see metrics
kubectl -n techcommerce-staging port-forward svc/frontend 8080:80 &
kubectl -n techcommerce-staging port-forward svc/product-api 8081:5000 &

# Make some requests
for i in {1..100}; do curl -s http://localhost:8080/healthz > /dev/null; done
for i in {1..100}; do curl -s http://localhost:8081/products > /dev/null; done
```

## 🔍 Useful Prometheus Queries

Access Prometheus at http://localhost:9090 and try these queries:

### Basic Metrics:
```promql
# Pod CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Pod memory usage  
container_memory_usage_bytes

# Pod restart count
kube_pod_container_status_restarts_total

# HTTP request rate (if apps have metrics)
rate(http_requests_total[5m])
```

### TechCommerce Specific:
```promql
# CPU usage for TechCommerce pods
rate(container_cpu_usage_seconds_total{namespace=~"techcommerce.*"}[5m])

# Memory usage for TechCommerce pods
container_memory_usage_bytes{namespace=~"techcommerce.*"}

# Pod count per deployment
kube_deployment_status_replicas{namespace=~"techcommerce.*"}
```

## 🏗️ Adding Application Metrics

To get more detailed metrics from your apps, you can add instrumentation:

### Node.js Apps (Frontend & Order API):
```javascript
// Add to package.json
"prom-client": "^14.2.0"

// Add to your app
const client = require('prom-client');
const register = client.register;

// Collect default metrics
client.collectDefaultMetrics();

// Custom metrics
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

// Expose metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(register.metrics());
});
```

### Python App (Product API):
```python
# Add to requirements.txt
prometheus_client==0.16.0

# Add to app.py
from prometheus_client import Counter, generate_latest
from flask import Response

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')
```

## 🚀 Quick Start Commands

Run these commands to get everything up and running:

```bash
# 1. Port-forward Grafana (run in background)
kubectl --namespace monitoring port-forward svc/kps-grafana 3000:80 &

# 2. Port-forward Prometheus (run in background)  
kubectl --namespace monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090 &

# 3. Deploy your apps to generate metrics
kubectl apply -k k8s/overlays/staging

# 4. Open dashboards
open http://localhost:3000  # Grafana (admin/prom-operator)
open http://localhost:9090  # Prometheus
```

## 🔧 Troubleshooting

### If services don't start:
```bash
# Check pod status
kubectl -n monitoring get pods

# Check logs
kubectl -n monitoring logs -l app=prometheus
kubectl -n monitoring logs -l app.kubernetes.io/name=grafana
```

### If metrics are missing:
```bash
# Check if ServiceMonitor is created
kubectl -n monitoring get servicemonitor

# Check Prometheus targets
# Go to http://localhost:9090/targets
```

### Reset Grafana password:
```bash
kubectl -n monitoring delete secret kps-grafana
kubectl -n monitoring rollout restart deployment/kps-grafana
```

Now you have a complete monitoring stack! 🎉

**Next**: Open http://localhost:3000, login with admin/prom-operator, and explore the pre-built Kubernetes dashboards!