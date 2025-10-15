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
- **SAST**: Code security scanning
- **Container scanning**: Trivy for vulnerabilities
- **Dependency scanning**: npm audit, pip-audit
- **Runtime security**: Non-root containers, resource limits

### Monitoring & Observability

#### Metrics Collection
- **Prometheus** for metrics collection
- **kube-prometheus-stack** for easy setup
- **Node Exporter** for system metrics
- **Service monitors** for application metrics

#### Alerting Rules
1. **Pod Restarts**: >3 restarts in 10 minutes
2. **API Response Time**: >2s 95th percentile for 5 minutes
3. **Error Rate**: >5% 5xx responses for 5 minutes
4. **Disk Usage**: >85% for 10 minutes

#### Dashboards
- **Grafana** for visualization
- Pre-built dashboards for Kubernetes metrics
- Custom dashboards for application-specific metrics

### Networking

#### Service Communication
- Internal DNS resolution: `service.namespace.svc.cluster.local`
- ClusterIP services for east-west traffic
- ConfigMap configuration for service endpoints

#### External Access
- Optional Ingress for external traffic
- Load balancer or NodePort for development
- TLS termination at ingress level

### Security Architecture

#### Container Security
- Non-root users (UID 10001)
- Read-only root filesystems where possible
- Minimal base images (Alpine, Distroless)
- Regular vulnerability scanning

#### Kubernetes Security
- Namespace isolation
- RBAC for service accounts
- Network policies (recommended for production)
- Pod security contexts

#### Secrets Management
- Kubernetes Secrets for basic needs
- External Secrets Operator (recommended for production)
- Sealed Secrets for GitOps workflows
- Rotation policies and monitoring

### Scalability & Performance

#### Horizontal Scaling
- HPA based on CPU utilization
- Custom metrics scaling (future enhancement)
- Cluster autoscaler for node scaling

#### Resource Management
- CPU/Memory requests and limits
- Quality of Service classes
- Priority classes for critical workloads

#### Caching Strategy
- Application-level caching
- CDN integration for static assets
- Database query optimization

### Disaster Recovery

#### Backup Strategy
- Persistent volume snapshots
- Configuration backup via GitOps
- Database backup procedures

#### High Availability
- Multi-zone deployments
- Pod anti-affinity rules
- Health checks and automatic recovery

#### Recovery Procedures
- Rollback mechanisms via kubectl
- Blue-green deployment capability
- Canary deployment patterns

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