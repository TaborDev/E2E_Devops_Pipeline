# 🚀 TechCommerce DevOps Pipeline - Restart Guide

## To Resume Work Tomorrow:

### 1. Start Minikube Cluster
```bash
minikube start
```

### 2. Verify Your Services Are Running
```bash
kubectl -n techcommerce-staging get pods
```

### 3. Set Up Port Forwarding for Your Application
```bash
# Frontend access (your app)
kubectl -n techcommerce-staging port-forward svc/frontend 8080:80 &

# Grafana monitoring dashboard
kubectl --namespace monitoring port-forward svc/kps-grafana 8081:80 &
```

### 4. Access Your Services

**Your TechCommerce Application:**
- URL: `http://localhost:8080`

**Grafana Monitoring Dashboard:**
- URL: `http://localhost:8081`
- Username: `admin`
- Password: `prom-operator`

### 5. View Your DevOps Project in Grafana
1. Go to `http://localhost:8081`
2. Login with admin/prom-operator
3. Navigate to: **Dashboards → Kubernetes / Compute Resources / Namespace (Pods)**
4. **Change namespace from "default" to "techcommerce-staging"**
5. See your microservices metrics!

### 6. Generate Traffic (Optional)
```bash
# Generate some requests to see metrics
for i in {1..10}; do curl -s http://localhost:8080/ && echo "Request $i completed"; sleep 1; done
```

## What's Currently Deployed:
- ✅ 3 Microservices (Frontend, Product API, Order API)
- ✅ Kubernetes Deployments with HPA (2-10 replicas)
- ✅ Prometheus + Grafana Monitoring Stack
- ✅ CI/CD Pipeline (GitHub Actions)
- ✅ Complete Documentation

## Quick Status Check:
```bash
# Check all namespaces
kubectl get pods --all-namespaces

# Check your services specifically
kubectl -n techcommerce-staging get all
```

---
Your complete DevOps pipeline is ready! Just run the commands above to resume. 🎉