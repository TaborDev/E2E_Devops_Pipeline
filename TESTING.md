# TechCommerce End-to-End Testing Guide

This guide walks you through testing the entire pipeline from local development to production deployment.

## 🧪 Testing Levels

### 1. Local Development Testing
### 2. Docker Container Testing  
### 3. Kubernetes Local Testing
### 4. CI/CD Pipeline Testing
### 5. End-to-End Integration Testing

---

## 🏠 1. Local Development Testing

### Prerequisites
```bash
# Install required tools
node --version  # Should be 20+
python --version  # Should be 3.11+
docker --version
kubectl version --client
```

### Test Each Service Locally

#### Frontend Service
```bash
cd services/frontend
npm install
npm test
npm start
# Test in browser: http://localhost:3000
# Health checks: 
curl http://localhost:3000/healthz
curl http://localhost:3000/livez
```

#### Product API Service
```bash
cd services/product-api
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pytest
python app.py
# Test in browser: http://localhost:5000
# Health checks:
curl http://localhost:5000/healthz
curl http://localhost:5000/products
```

#### Order API Service
```bash
cd services/order-api
npm install
npm test
npm start
# Test in browser: http://localhost:7000
# Health checks:
curl http://localhost:7000/healthz
curl http://localhost:7000/orders
```

---

## 🐳 2. Docker Container Testing

### Build and Test Each Service

#### Frontend
```bash
cd services/frontend
docker build -t techcommerce-frontend:test .
docker run -p 3000:3000 techcommerce-frontend:test
# Test health endpoints
curl http://localhost:3000/healthz
```

#### Product API
```bash
cd services/product-api
docker build -t techcommerce-product-api:test .
docker run -p 5000:5000 techcommerce-product-api:test
curl http://localhost:5000/products
```

#### Order API
```bash
cd services/order-api
docker build -t techcommerce-order-api:test .
docker run -p 7000:7000 techcommerce-order-api:test
curl http://localhost:7000/orders
```

### Test Multi-Service Communication
```bash
# Create a test network
docker network create techcommerce-test

# Run all services on the network
docker run -d --name product-api --network techcommerce-test -p 5000:5000 techcommerce-product-api:test
docker run -d --name order-api --network techcommerce-test -p 7000:7000 techcommerce-order-api:test
docker run -d --name frontend --network techcommerce-test -p 3000:3000 \
  -e FRONTEND_API_BASE_URL=http://product-api:5000 \
  -e ORDER_API_BASE_URL=http://order-api:7000 \
  techcommerce-frontend:test

# Test integration
curl http://localhost:3000
curl http://localhost:5000/products
curl http://localhost:7000/orders

# Cleanup
docker stop frontend product-api order-api
docker rm frontend product-api order-api
docker network rm techcommerce-test
```

---

## ☸️ 3. Kubernetes Local Testing

### Prerequisites
```bash
# Set up local Kubernetes (choose one)
# Option 1: Kind
kind create cluster --name techcommerce

# Option 2: k3d
k3d cluster create techcommerce

# Option 3: Docker Desktop Kubernetes (enable in settings)
```

### Deploy to Local Kubernetes

#### Step 1: Install Monitoring Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

#### Step 2: Create Secrets
```bash
# Copy and edit secrets
cp k8s/base/secrets.example.yaml k8s/base/secrets.yaml
# Edit secrets.yaml with real values (can be dummy for testing)

# Update kustomization.yaml to use secrets.yaml
sed -i 's/secrets.example.yaml/secrets.yaml/' k8s/base/kustomization.yaml
```

#### Step 3: Deploy to Staging
```bash
# Update image references in kustomization
export REGISTRY="your-registry.com/your-username"  # or use "local" for local testing
sed -i "s|REPLACE_REGISTRY|${REGISTRY}|g" k8s/base/kustomization.yaml

# If using local images, load them into cluster
# For kind:
kind load docker-image techcommerce-frontend:test --name techcommerce
kind load docker-image techcommerce-product-api:test --name techcommerce
kind load docker-image techcommerce-order-api:test --name techcommerce

# For local testing, update image tags to "test"
sed -i 's/staging/test/g' k8s/overlays/staging/kustomization.yaml

# Deploy
kubectl apply -k k8s/overlays/staging
```

#### Step 4: Verify Deployment
```bash
# Check all resources
kubectl get all -n techcommerce-staging

# Check pod status
kubectl get pods -n techcommerce-staging

# Check HPA
kubectl get hpa -n techcommerce-staging

# Check services
kubectl get svc -n techcommerce-staging
```

#### Step 5: Test Services
```bash
# Port forward to test services
kubectl port-forward -n techcommerce-staging svc/frontend 8080:80 &
kubectl port-forward -n techcommerce-staging svc/product-api 8081:5000 &
kubectl port-forward -n techcommerce-staging svc/order-api 8082:7000 &

# Test endpoints
curl http://localhost:8080
curl http://localhost:8080/healthz
curl http://localhost:8081/products
curl http://localhost:8082/orders

# Stop port forwarding
pkill -f "kubectl port-forward"
```

#### Step 6: Test HPA Scaling
```bash
# Generate load to trigger HPA
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://product-api.techcommerce-staging.svc.cluster.local:5000/products; done

# In another terminal, watch HPA scaling
kubectl get hpa -n techcommerce-staging -w

# Watch pods scaling
kubectl get pods -n techcommerce-staging -w
```

---

## 🔄 4. CI/CD Pipeline Testing

### Prerequisites
```bash
# Set up GitHub repository secrets:
# REGISTRY - your container registry (e.g., ghcr.io/username)
# REGISTRY_USERNAME - registry username
# REGISTRY_PASSWORD - registry password/token
# KUBE_CONFIG - base64 encoded kubeconfig for your cluster
```

### Test GitHub Actions Workflow

#### Step 1: Trigger Pipeline
```bash
# Push changes to main branch
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin main

# Or manually trigger via GitHub UI
# Go to Actions tab -> CI-CD workflow -> Run workflow
```

#### Step 2: Monitor Pipeline
```bash
# Check pipeline status via GitHub UI or CLI
gh run list
gh run view <run-id>
```

#### Step 3: Verify Staging Deployment
```bash
# Check if staging deployment succeeded
kubectl get pods -n techcommerce-staging
kubectl rollout status deployment/frontend -n techcommerce-staging
kubectl rollout status deployment/product-api -n techcommerce-staging
kubectl rollout status deployment/order-api -n techcommerce-staging
```

#### Step 4: Test Manual Production Approval
```bash
# Production deployment requires manual approval
# Check GitHub Actions UI for pending approval
# Approve and monitor production deployment
kubectl get pods -n techcommerce-prod
```

#### Step 5: Test Rollback
```bash
# Simulate a failed deployment by introducing a bug
# Then test rollback
kubectl rollout undo deployment/frontend -n techcommerce-prod
kubectl rollout undo deployment/product-api -n techcommerce-prod
kubectl rollout undo deployment/order-api -n techcommerce-prod
```

---

## 🔍 5. End-to-End Integration Testing

### Test Complete User Journey

#### Step 1: Access Frontend
```bash
# Get frontend URL (adjust based on your setup)
kubectl get svc -n techcommerce-staging frontend

# If using port-forward
kubectl port-forward -n techcommerce-staging svc/frontend 8080:80
```

#### Step 2: Test API Integration
```bash
# Test frontend -> product API communication
curl http://localhost:8080
# Should show frontend page with API URLs

# Test direct API calls
curl http://localhost:8081/products
curl http://localhost:8082/orders
```

#### Step 3: Test Monitoring and Alerts

```bash
# Access Prometheus
kubectl port-forward -n monitoring svc/kps-kube-prometheus-stack-prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring svc/kps-grafana 3000:80
# Default credentials: admin/prom-operator

# Check custom alert rules
# Open Prometheus UI -> Alerts
# Look for techcommerce-alerts rules
```

#### Step 4: Test Alert Conditions
```bash
# Test pod restart alert
kubectl delete pod -n techcommerce-staging -l app=frontend
# Repeat a few times to trigger alert

# Test high CPU for HPA alert
kubectl run -n techcommerce-staging --rm -i load-test --image=busybox -- /bin/sh
# Generate high CPU load on product-api pods
```

---

## 🚨 Troubleshooting Common Issues

### Images Not Found
```bash
# Check if images exist in registry
docker pull your-registry.com/techcommerce-frontend:staging

# For local testing, use local images
# Update kustomization.yaml to use local tags
```

### Pod CrashLoopBackOff
```bash
kubectl logs -n techcommerce-staging <pod-name>
kubectl describe pod -n techcommerce-staging <pod-name>
```

### Services Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n techcommerce-staging

# Check network policies
kubectl get networkpolicies -n techcommerce-staging
```

### HPA Not Scaling
```bash
# Check metrics server
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa -n techcommerce-staging product-api-hpa
```

### Monitoring Not Working
```bash
# Check Prometheus operator
kubectl get pods -n monitoring

# Check service monitors
kubectl get servicemonitor -n monitoring
```

---

## ✅ Success Criteria Checklist

- [ ] All services build successfully locally
- [ ] All Docker containers run and respond to health checks
- [ ] Kubernetes deployment succeeds without errors
- [ ] All pods are in Running state
- [ ] Services are accessible via port-forwarding
- [ ] HPA scales pods under load
- [ ] CI/CD pipeline runs without failures
- [ ] Images are pushed to registry
- [ ] Staging deployment is automatic
- [ ] Production deployment requires manual approval
- [ ] Monitoring stack is operational
- [ ] Custom alert rules are loaded
- [ ] Services can communicate with each other
- [ ] Health checks pass consistently
- [ ] Rollback functionality works

---

## 📊 Performance Testing (Optional)

### Load Testing with k6
```bash
# Install k6
brew install k6  # macOS
# or download from https://k6.io/

# Create load test script
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 10,
  duration: '30s',
};

export default function() {
  let response = http.get('http://localhost:8081/products');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
EOF

# Run load test
k6 run load-test.js
```

This comprehensive testing guide ensures your TechCommerce microservices pipeline works correctly at every level!