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
