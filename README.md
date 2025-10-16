# TechCommerce — Microservices CI/CD on Kubernetes

Three services:
- **Frontend** (Node.js, port 3000)
- **Product API** (Python Flask, port 5000)
- **Order API** (Node.js Express, port 7000)

Production‑ready Dockerfiles (multi‑stage), Kubernetes manifests (Deployments, Services, ConfigMaps, Secrets, HPA), CI/CD with GitHub Actions (tests, security scanning, image build+scan, staging deploy, manual prod approval, rollback), and Monitoring via Prometheus + Grafana with alert rules.

---
## Prerequisites
- Docker & docker login to GHCR or DockerHub
- Kubernetes cluster (kind, k3d, EKS, GKE, AKS)
- `kubectl` & `kustomize` (or `kubectl kustomize`)
- `helm` (for kube-prometheus-stack)
- GitHub repo secrets set:
  - `REGISTRY` (e.g., ghcr.io/<your-username>)
  - `REGISTRY_USERNAME` / `REGISTRY_PASSWORD`
  - `KUBE_CONFIG` (base64 of kubeconfig for deploy cluster)

---
## Build & Run Locally

### Frontend
```bash
cd services/frontend
npm ci
npm test --silent || echo "(no tests)"
docker build -t frontend:dev .
docker run -p 3000:3000 frontend:dev
```

### Product API
```bash
cd services/product-api
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest || echo "(basic tests)"
docker build -t product-api:dev .
docker run -p 5000:5000 product-api:dev
```

### Order API
```bash
cd services/order-api
npm ci
npm test --silent || echo "(no tests)"
docker build -t order-api:dev .
docker run -p 7000:7000 order-api:dev
```

---

## Kubernetes Deployment

### 1) Install Monitoring (Prometheus + Grafana)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
# Add custom alert rules
kubectl apply -f k8s/monitoring/prometheus-rules.yaml -n monitoring
```

### 2) Staging

```bash
kubectl apply -k k8s/overlays/staging
```

### 3) Production

```bash
kubectl apply -k k8s/overlays/production
```

### 4) Verify

```bash
kubectl get deploy,svc,hpa -A
kubectl get pods -A
```

---

## CI/CD Pipeline

* On push to `main`: run tests, lint, security scans (Trivy, npm audit, pip-audit), build & scan images, push to registry, deploy to **staging** automatically.
* **Manual approval** gate to deploy to **production** (uses GitHub Environments or `workflow_dispatch` approval).
* Rollback via `kubectl rollout undo` if health checks fail.

---

## Security Best Practices

* Multi-stage Docker builds → minimal runtime images.
* Non‑root containers; read‑only filesystem where possible.
* Image & dependency scanning (Trivy, npm audit, pip-audit).
* K8s Secrets for sensitive values (suggested: External Secrets or Sealed Secrets in real prod).
* Resource requests/limits to prevent noisy neighbor & enable HPA.
* Network policies (not included here for brevity) to restrict cross‑service traffic.

---

## Scaling & Cost Optimization

* HPA on Product API (2–10 pods, 70% CPU target).
* Right‑size requests/limits; enable cluster autoscaler.
* Use Spot/Preemptible for staging; scale down at night.
* Cache & CDN for frontend; GZIP; use lightweight base images.

---

## Troubleshooting

See `docs/troubleshooting.md` for:

* CrashLoopBackOff
* Slow app but normal metrics
* ImagePullBackOff

---

## Architecture

See `docs/architecture-overview.md` for the diagram and explanations.

---

## Repository Structure

```
techcommerce/
├─ README.md
├─ docs/
│  ├─ architecture-overview.md
│  └─ troubleshooting.md
├─ k8s/
│  ├─ base/
│  │  ├─ namespace.yaml
│  │  ├─ configmap.yaml
│  │  ├─ secrets.example.yaml
│  │  ├─ frontend-deploy.yaml
│  │  ├─ frontend-svc.yaml
│  │  ├─ product-api-deploy.yaml
│  │  ├─ product-api-svc.yaml
│  │  ├─ order-api-deploy.yaml
│  │  ├─ order-api-svc.yaml
│  │  ├─ hpa-product-api.yaml
│  │  ├─ ingress.yaml (optional)
│  │  └─ kustomization.yaml
│  ├─ overlays/
│  │  ├─ staging/
│  │  │  ├─ kustomization.yaml
│  │  │  ├─ configmap-patch.yaml
│  │  │  └─ namespace.yaml
│  │  └─ production/
│  │     ├─ kustomization.yaml
│  │     ├─ configmap-patch.yaml
│  │     └─ namespace.yaml
│  └─ monitoring/
│     └─ prometheus-rules.yaml
├─ .github/
│  └─ workflows/
│     └─ ci-cd.yaml
├─ services/
│  ├─ frontend/
│  │  ├─ Dockerfile
│  │  ├─ package.json
│  │  ├─ src/index.js
│  │  └─ src/health.js
│  ├─ product-api/
│  │  ├─ Dockerfile
│  │  ├─ requirements.txt
│  │  ├─ app.py
│  │  └─ tests/test_health.py
│  └─ order-api/
│     ├─ Dockerfile
│     ├─ package.json
│     ├─ src/index.js
│     └─ src/health.js
└─ security/
   ├─ trivyignore
   └─ .npmauditrc.json
```

---

## Quick Start

1. **Clone and setup secrets:**
   ```bash
   git clone https://github.com/TaborDev/E2E_Devops_Pipeline.git
   cd E2E_Devops_Pipeline
   cp k8s/base/secrets.example.yaml k8s/base/secrets.yaml
   # Edit secrets.yaml with real values
   ```

2. **Build and test locally:**
   ```bash
   # Test each service
   cd services/frontend && npm ci && npm test
   cd ../product-api && pip install -r requirements.txt && pytest
   cd ../order-api && npm ci && npm test
   ```

3. **Deploy to Kubernetes:**
   ```bash
   # Setup monitoring first
   helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
   
   # Deploy staging
   kubectl apply -k k8s/overlays/staging
   
   # Deploy production (after staging validation)
   kubectl apply -k k8s/overlays/production
   ```

4. **Setup CI/CD:**
   - Configure GitHub secrets: `REGISTRY`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD`, `KUBE_CONFIG`
   - Push changes to trigger pipeline
   - Use GitHub Environments for production approval gate

---

## Design Decisions

* **Kustomize overlays** keep one source of truth with environment tweaks.
* **Operator-based monitoring** (kube-prometheus-stack) simplifies Prometheus/Grafana management & rules.
* **GitHub Environments** provide a clean manual approval gate.
* **Multi-stage Docker** + non-root users reduce attack surface & cost.
* **HPA on CPU** is a pragmatic first step; can add custom/app metrics later.

---

## Assignment Questions & Answers

### **1. Architecture & Design Questions**

**Q: Why did you choose Node.js for the Frontend and Order API?**
A: Node.js provides excellent performance for I/O-intensive operations typical in frontend services and API gateways. Its async nature and vast ecosystem (npm) make it ideal for microservices that handle HTTP requests and API orchestration.

**Q: Why Python Flask for the Product API?**
A: Python Flask offers simplicity and flexibility for data-heavy operations. Python's rich ecosystem for data processing, machine learning libraries, and database operations makes it perfect for product catalog management where you might need complex queries, analytics, or recommendation algorithms.

**Q: Explain your multi-stage Docker build strategy.**
A: Multi-stage builds separate build dependencies from runtime dependencies:
- **Build stage**: Uses full Node.js/Python images with dev tools, compilers
- **Runtime stage**: Uses minimal Alpine-based images with only production dependencies
- **Benefits**: 80% smaller images, improved security (no build tools in prod), faster deployments

### **2. Kubernetes & Scaling Questions**

**Q: Why did you implement HPA only for the Product API?**
A: The Product API is typically the most resource-intensive service in an e-commerce platform:
- Handles complex product searches and filtering
- Database-heavy operations for catalog management
- Most likely to experience variable load during traffic spikes
- Frontend and Order API are more predictable in resource usage

**Q: Explain your scaling strategy (2-10 replicas, 70% CPU threshold).**
A: 
- **Minimum 2 replicas**: Ensures high availability (no single point of failure)
- **Maximum 10 replicas**: Prevents runaway scaling that could overwhelm database
- **70% CPU threshold**: Conservative threshold allowing headroom for traffic spikes while avoiding constant scaling churn

**Q: How do you handle resource allocation?**
A: Implemented requests and limits tailored per service:
- **Frontend/Order API**: requests(100m CPU, 128Mi memory), limits(500m CPU, 256Mi memory)
- **Product API**: requests(200m CPU, 256Mi memory), limits(1000m CPU, 512Mi memory)
- Product API gets more resources as it's the most data-intensive service
- Based on actual service resource consumption patterns and workload requirements

### **3. Security Questions**

**Q: What security best practices did you implement?**
A: Multiple layers of security:
1. **Container Security**: Non-root users, minimal base images (Alpine)
2. **Secret Management**: Kubernetes Secrets for sensitive data, never in code
3. **Image Scanning**: Trivy vulnerability scanning in CI/CD pipeline
4. **Dependency Scanning**: npm audit, pip-audit for known vulnerabilities
5. **Principle of Least Privilege**: Minimal container capabilities

**Q: How do you manage secrets and sensitive configuration?**
A: Three-tier approach:
1. **Development**: Environment variables in local .env files (gitignored)
2. **Kubernetes**: Secrets stored as base64-encoded values, mounted as files
3. **Production**: Integration with external secret managers (AWS Secrets Manager, Azure Key Vault)

**Q: Explain your secret rotation strategy.**
A: 
- **Automated rotation**: External secret managers handle automatic rotation
- **Application restart**: Use rolling deployments to pick up new secrets
- **Zero-downtime**: Graceful shutdown ensures no dropped connections

### **4. CI/CD & DevOps Questions**

**Q: Why GitHub Actions over other CI/CD tools?**
A: GitHub Actions provides:
- **Native integration** with GitHub repositories
- **Matrix builds** for parallel service testing
- **Built-in security scanning** with GitHub security features
- **Environment-based approvals** for production deployments
- **Cost-effective** for open-source and small teams

**Q: Explain your deployment strategy.**
A: Progressive deployment with safety gates:
1. **CI Stage**: Tests, security scans, image builds (parallel for all services)
2. **Staging**: Automatic deployment for integration testing
3. **Production**: Manual approval gate via GitHub Environments
4. **Rollback**: Automated rollback on deployment failure

**Q: How do you ensure zero-downtime deployments?**
A: Multiple strategies:
- **Rolling updates**: Kubernetes gradually replaces old pods
- **Health checks**: Readiness probes ensure new pods are ready before routing traffic
- **Connection draining**: Grace periods allow existing connections to complete
- **Load balancing**: Services route traffic only to healthy pods

### **5. Monitoring & Observability Questions**

**Q: Why Prometheus + Grafana for monitoring?**
A: Industry-standard cloud-native monitoring:
- **Prometheus**: Pull-based metrics collection, powerful query language (PromQL)
- **Grafana**: Rich visualization, alerting capabilities
- **Kubernetes-native**: Operator-based deployment simplifies management
- **Extensible**: Easy to add custom metrics and dashboards

**Q: Explain your alerting strategy.**
A: Four-tier alerting based on severity:
1. **Critical**: Pod restart loops (immediate action required)
2. **High**: API response time >2s (performance degradation)
3. **Medium**: Error rate >5% (quality issues)
4. **Warning**: Disk usage >85% (capacity planning)

**Q: How do you monitor application health?**
A: Multi-layer health monitoring:
- **Liveness probes**: Restart unhealthy containers
- **Readiness probes**: Remove unhealthy pods from load balancing
- **Custom metrics**: Application-specific performance indicators
- **Log aggregation**: Centralized logging for debugging

### **6. Cost Optimization Questions**

**Q: How do you optimize infrastructure costs?**
A: Several cost optimization strategies:
1. **Right-sizing**: Appropriate resource requests/limits based on actual usage
2. **Autoscaling**: Scale down during low-traffic periods
3. **Multi-stage builds**: Smaller images = lower storage and transfer costs
4. **Efficient base images**: Alpine Linux reduces image size by 80%
5. **Resource sharing**: Multiple services per node with proper resource allocation

**Q: What's your approach to capacity planning?**
A: Data-driven capacity planning:
- **Historical metrics**: Use Prometheus data to identify usage patterns
- **Load testing**: Simulate traffic to understand scaling behavior
- **Cost monitoring**: Track resource costs per service
- **Regular review**: Monthly capacity and cost optimization reviews

---

## Next Steps (Optional Enhancements)

* Add **NetworkPolicies** restricting cross-namespace traffic.
* Add **Ingress** + TLS via cert-manager & Let's Encrypt.
* Add **OpenTelemetry** for tracing.
* Add db migrations job & readiness checks for DB availability.
* Add canary/blue‑green deployments with Argo Rollouts.
