# Architecture Overview

## System Architecture

The TechCommerce platform follows a microservices architecture with three main services:

### Services

1. **Frontend Service (Node.js)**
   - Port: 3000
   - Technology: Express.js
   - Purpose: User interface and API gateway
   - Health endpoints: `/healthz`, `/livez`

2. **Product API (Python Flask)**
   - Port: 5000
   - Technology: Flask
   - Purpose: Product catalog management
   - Features: Product listing, search, management
   - Health endpoints: `/healthz`, `/livez`

3. **Order API (Node.js)**
   - Port: 7000
   - Technology: Express.js
   - Purpose: Order processing and management
   - Features: Order creation, tracking, fulfillment
   - Health endpoints: `/healthz`, `/livez`

### Docker Strategy

- **Multi-stage builds** for minimal production images
- **Non-root containers** for security
- **Alpine Linux** base images where possible
- **Build caching** optimization for faster CI/CD

### Kubernetes Architecture

#### Deployments
- Each service deployed as separate Deployment
- **2 replicas minimum** for high availability
- **Resource requests/limits** for proper scheduling
- **Security contexts** with non-root users

#### Services
- ClusterIP services for internal communication
- Service discovery via DNS names
- Port mapping: service port to container port

#### Configuration Management
- **ConfigMaps** for non-sensitive configuration
- **Secrets** for sensitive data (DB connections, API keys)
- Environment-specific overlays with Kustomize

#### Auto-scaling
- **Horizontal Pod Autoscaler (HPA)** on Product API
- Scale range: 2-10 pods
- CPU threshold: 70% utilization
- Requires metrics-server

#### Health Checks
- **Readiness probes** prevent traffic to unready pods
- **Liveness probes** restart unhealthy containers
- HTTP-based health endpoints on all services

### CI/CD Pipeline Architecture

#### Stages

1. **Continuous Integration**
   - Parallel builds for all services
   - Language-specific testing (npm test, pytest)
   - Security scanning (npm audit, pip-audit)
   - Docker image building and scanning (Trivy)

2. **Image Management**
   - Multi-architecture builds
   - Registry push with multiple tags
   - Vulnerability scanning before deployment

3. **Deployment Stages**
   - **Staging**: Automatic deployment after CI success
   - **Production**: Manual approval gate via GitHub Environments
   - **Rollback**: Automated on deployment failure

#### Security Integration
- **SAST**: Code security scanning. No SAST tools (like SonarQube, Semgrep, or CodeQL) configured in the CI/CD workflow
- **Container scanning**: Trivy for vulnerabilities
- **Dependency scanning**: npm audit, pip-audit. Partially implemented in npm audit and pip-audit
- **Runtime security**: Non-root containers, resource limits

## Monitoring & Observability

### Current Implementation Status

**Installed Components**:
- Prometheus (via kube-prometheus-stack)
- Grafana (via kube-prometheus-stack)
- Basic Kubernetes metrics collection

**Partially Implemented**:
- **Grafana Dashboards**: Only default dashboards available
- **Node Exporter**: Installed but not verified
- **Service Monitors**: Basic setup, needs application-specific configuration

**Not Yet Implemented**:
- Custom alert rules for pod restarts, API response times, etc.
- Application-specific dashboards
- Log aggregation (Loki stack attempted but not fully configured)
- Distributed tracing (OpenTelemetry)

### How to Access

1. **Grafana Dashboard**:
   ```bash
   kubectl port-forward -n monitoring svc/kps-grafana 3000:80
   # Open http://localhost:3000
   # Default credentials: admin/prom-operator

### Networking

#### Service Communication
- Internal DNS resolution: `service.namespace.svc.cluster.local`
- ClusterIP services for east-west traffic
- ConfigMap configuration for service endpoints

### Security Architecture

#### Container Security
- Non-root users (UID 10001)
- Read-only root filesystems where possible

#### Kubernetes Security
- Namespace isolation
- RBAC for service accounts : Only default roles in use

#### Secrets Management
- Kubernetes Secrets for basic needs

### Scalability & Performance

#### Horizontal Scaling
- HPA based on CPU utilization
- Cluster autoscaler for node scaling

#### Resource Management
- CPU/Memory requests and limits
- Quality of Service classes
- Priority classes for critical workloads
- Health checks and automatic recovery

#### Recovery Procedures
- Rollback mechanisms via kubectl [Maual only]

### Technology Stack Summary

| Component | Technology | Purpose |
|-----------|------------|---------|
| Frontend | Node.js + Express | Web UI & API Gateway |
| Product API | Python + Flask | Product Management |
| Order API | Node.js + Express | Order Processing |
| Container Runtime | Docker | Application Packaging |
| Orchestration | Kubernetes | Container Management |
| CI/CD | GitHub Actions | Automation Pipeline |
| Monitoring | Prometheus + Grafana | Observability |
| Configuration | Kustomize | Environment Management |
| Security | Trivy + npm audit | Vulnerability Scanning |

### Design Principles

1. **Microservices**: Loosely coupled, independently deployable
2. **Infrastructure as Code**: All infrastructure defined in code
3. **GitOps**: Configuration managed through Git workflows
4. **Security by Default**: Security built into every layer
5. **Observability**: Comprehensive monitoring and logging
6. **Automation**: Minimize manual operations
7. **Scalability**: Design for growth and load variations