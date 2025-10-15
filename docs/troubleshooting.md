# Troubleshooting Guide

## Common Issues and Solutions

### 1. Pods in CrashLoopBackOff

**Symptoms:**
- Pods continuously restart
- Status shows `CrashLoopBackOff`
- Application appears unavailable

**Diagnosis Steps:**

1. **Check Pod Events:**
   ```bash
   kubectl -n <namespace> describe pod <pod-name>
   ```
   Look for:
   - Container exit codes (0=success, 1=general error, 125=Docker daemon error)
   - Resource constraints (OOMKilled)
   - Image pull issues
   - Mount failures

2. **Examine Container Logs:**
   ```bash
   kubectl -n <namespace> logs <pod-name> -c <container-name>
   kubectl -n <namespace> logs <pod-name> -c <container-name> --previous
   ```

3. **Check Resource Usage:**
   ```bash
   kubectl -n <namespace> top pods
   kubectl -n <namespace> describe node <node-name>
   ```

**Common Causes and Solutions:**

#### Memory Issues (OOMKilled)
```bash
# Increase memory limits
spec:
  containers:
  - name: container
    resources:
      limits:
        memory: "512Mi"  # Increase from 256Mi
      requests:
        memory: "256Mi"  # Increase from 128Mi
```

#### Environment Variable Errors
```bash
# Check ConfigMap and Secret values
kubectl -n <namespace> get configmap app-config -o yaml
kubectl -n <namespace> get secret app-secrets -o yaml
```

#### Health Check Failures
```bash
# Verify health endpoints
kubectl -n <namespace> exec -it <pod-name> -- wget -qO- localhost:3000/healthz

# Adjust probe settings
readinessProbe:
  httpGet:
    path: /healthz
    port: 3000
  initialDelaySeconds: 10  # Increase from 5
  periodSeconds: 15        # Increase from 10
```

#### Application Startup Issues
```bash
# Check for missing dependencies or configuration
kubectl -n <namespace> exec -it <pod-name> -- sh
# Test the application command manually
```

### 2. Application is Slow but Metrics Look Normal

**Symptoms:**
- High response times reported by users
- CPU and memory usage appear normal
- No obvious errors in logs

**Diagnosis Steps:**

1. **Check Downstream Dependencies:**
   ```bash
   # Test external API connectivity
   kubectl -n <namespace> exec -it <pod-name> -- curl -v http://external-api.com/health
   
   # Check DNS resolution
   kubectl -n <namespace> exec -it <pod-name> -- nslookup service-name
   ```

2. **Network Analysis:**
   ```bash
   # Check service endpoints
   kubectl -n <namespace> get endpoints
   
   # Verify service connectivity
   kubectl -n <namespace> exec -it <pod-name> -- nc -zv service-name 5000
   ```

3. **Enable Distributed Tracing:**
   ```bash
   # Add OpenTelemetry instrumentation (example for Node.js)
   const { NodeSDK } = require('@opentelemetry/sdk-node');
   const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
   
   const sdk = new NodeSDK({
     instrumentations: [getNodeAutoInstrumentations()]
   });
   sdk.start();
   ```

4. **Database Performance:**
   ```bash
   # Check database connection pool
   # Monitor slow queries
   # Verify database indexes
   ```

**Common Causes and Solutions:**

#### DNS Resolution Delays
```bash
# Add DNS policy to pod spec
spec:
  dnsPolicy: ClusterFirst
  dnsConfig:
    options:
    - name: ndots
      value: "2"
    - name: edns0
```

#### Connection Pool Exhaustion
```bash
# Increase connection pool size
# Add connection timeouts
# Implement circuit breakers
```

#### Inefficient Service Communication
```bash
# Use service mesh for observability
# Implement caching between services
# Optimize API calls (batching, async)
```

#### Resource Contention
```bash
# Check node resource utilization
kubectl top nodes

# Look for noisy neighbors
kubectl -n <namespace> top pods --sort-by=cpu
kubectl -n <namespace> top pods --sort-by=memory
```

### 3. ImagePullBackOff Errors

**Symptoms:**
- Pods stuck in `ImagePullBackOff` or `ErrImagePull`
- New deployments fail to start
- Image-related error messages

**Diagnosis Steps:**

1. **Check Image Details:**
   ```bash
   kubectl -n <namespace> describe pod <pod-name>
   ```
   Look for:
   - Exact error message
   - Image name and tag
   - Registry information

2. **Verify Image Exists:**
   ```bash
   # Check if image exists in registry
   docker pull <registry>/<image>:<tag>
   
   # List available tags
   curl -s https://api.github.com/repos/<owner>/<repo>/packages
   ```

3. **Check Registry Authentication:**
   ```bash
   kubectl -n <namespace> get secrets
   kubectl -n <namespace> describe secret <registry-secret>
   ```

**Common Causes and Solutions:**

#### Image Does Not Exist
```bash
# Verify correct image name and tag
spec:
  containers:
  - name: frontend
    image: ghcr.io/username/techcommerce-frontend:v1.0.0  # Check tag exists
```

#### Registry Authentication Issues
```bash
# Create registry secret
kubectl create secret docker-registry regcred \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token> \
  --docker-email=<email>

# Add to deployment
spec:
  template:
    spec:
      imagePullSecrets:
      - name: regcred
```

#### Network/Proxy Issues
```bash
# Check cluster's egress connectivity
kubectl run debug --image=busybox -it --rm -- sh
# Test connectivity to registry
wget -O- https://ghcr.io/v2/_catalog
```

#### Registry Rate Limiting
```bash
# Use image pull policy to reduce pulls
spec:
  containers:
  - name: container
    imagePullPolicy: IfNotPresent  # Don't pull if image exists locally
```

### 4. Service Discovery Issues

**Symptoms:**
- Services cannot communicate with each other
- "Connection refused" or "Host not found" errors
- Intermittent connectivity issues

**Diagnosis Steps:**

1. **Check Service Configuration:**
   ```bash
   kubectl -n <namespace> get svc
   kubectl -n <namespace> describe svc <service-name>
   ```

2. **Verify Endpoints:**
   ```bash
   kubectl -n <namespace> get endpoints <service-name>
   ```

3. **Test DNS Resolution:**
   ```bash
   kubectl -n <namespace> exec -it <pod-name> -- nslookup <service-name>
   kubectl -n <namespace> exec -it <pod-name> -- nslookup <service-name>.<namespace>.svc.cluster.local
   ```

**Solutions:**

#### Service Selector Mismatch
```yaml
# Ensure service selector matches pod labels
apiVersion: v1
kind: Service
metadata:
  name: product-api
spec:
  selector:
    app: product-api  # Must match pod labels
  ports:
  - port: 5000
    targetPort: 5000
```

#### Port Configuration Issues
```yaml
# Verify port mapping
spec:
  containers:
  - name: product-api
    ports:
    - containerPort: 5000  # Container port
---
apiVersion: v1
kind: Service
spec:
  ports:
  - port: 5000        # Service port
    targetPort: 5000  # Must match containerPort
```

### 5. Resource and Performance Issues

**Symptoms:**
- Pods being OOMKilled
- CPU throttling
- Slow application performance
- Node resource exhaustion

**Diagnosis:**

1. **Check Resource Usage:**
   ```bash
   kubectl top nodes
   kubectl top pods -A --sort-by=memory
   kubectl top pods -A --sort-by=cpu
   ```

2. **Review Resource Specifications:**
   ```bash
   kubectl -n <namespace> describe pod <pod-name>
   ```

**Solutions:**

#### Right-size Resource Requests and Limits
```yaml
spec:
  containers:
  - name: product-api
    resources:
      requests:
        cpu: "200m"     # Guaranteed CPU
        memory: "256Mi" # Guaranteed memory
      limits:
        cpu: "1000m"    # Maximum CPU
        memory: "512Mi" # Maximum memory (prevent OOM)
```

#### Enable Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 6. Health Check Failures

**Symptoms:**
- Readiness probe failures
- Pods not receiving traffic
- Service unavailable errors

**Diagnosis:**
```bash
# Test health endpoints manually
kubectl -n <namespace> exec -it <pod-name> -- curl localhost:3000/healthz
kubectl -n <namespace> exec -it <pod-name> -- curl localhost:3000/livez
```

**Solutions:**

#### Adjust Probe Timing
```yaml
readinessProbe:
  httpGet:
    path: /healthz
    port: 3000
  initialDelaySeconds: 15  # Allow more startup time
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /livez
    port: 3000
  initialDelaySeconds: 30  # Allow even more time for liveness
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3
```

### 7. Deployment and Rollout Issues

**Symptoms:**
- Deployments stuck in progress
- New pods not coming up
- Rollback needed

**Commands:**

```bash
# Check deployment status
kubectl -n <namespace> rollout status deployment/<deployment-name>

# View deployment history
kubectl -n <namespace> rollout history deployment/<deployment-name>

# Rollback to previous version
kubectl -n <namespace> rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl -n <namespace> rollout undo deployment/<deployment-name> --to-revision=2

# Pause/resume deployment
kubectl -n <namespace> rollout pause deployment/<deployment-name>
kubectl -n <namespace> rollout resume deployment/<deployment-name>
```

### 8. Security and RBAC Issues

**Symptoms:**
- Permission denied errors
- Unable to access resources
- Authentication failures

**Diagnosis:**
```bash
# Check service account permissions
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<service-account>

# List RBAC for service account
kubectl describe serviceaccount <service-account> -n <namespace>
kubectl describe rolebinding -n <namespace>
kubectl describe clusterrolebinding
```

### General Debugging Tools

#### Essential Commands
```bash
# Get all resources in namespace
kubectl -n <namespace> get all

# Describe all pods in namespace
kubectl -n <namespace> describe pods

# Get events (recent activity)
kubectl -n <namespace> get events --sort-by='.lastTimestamp'

# Follow logs for all containers in deployment
kubectl -n <namespace> logs -f deployment/<deployment-name> --all-containers=true

# Port forward for local testing
kubectl -n <namespace> port-forward svc/<service-name> 8080:80

# Execute commands in running pod
kubectl -n <namespace> exec -it <pod-name> -- sh
```

#### Debug Pod for Network Testing
```bash
# Create debug pod
kubectl run debug --image=busybox -it --rm -- sh

# Or with more tools
kubectl run debug --image=nicolaka/netshoot -it --rm -- sh
```

This troubleshooting guide covers the most common issues encountered in Kubernetes deployments. For production environments, consider implementing comprehensive monitoring, alerting, and log aggregation to proactively identify and resolve issues.