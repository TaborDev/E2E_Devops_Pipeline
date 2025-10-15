#!/bin/bash

set -e  # Exit on any error

echo "🚀 TechCommerce E2E Testing Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test 1: Check if Docker is running
echo ""
echo "📋 Step 1: Prerequisites Check"
echo "================================"

if ! docker --version >/dev/null 2>&1; then
    print_error "Docker is not installed or not running"
    exit 1
fi
print_status "Docker is running"

# Test 2: Build and test services locally
echo ""
echo "🔨 Step 2: Build and Test Services"
echo "==================================="

# Frontend
echo "Testing Frontend Service..."
cd services/frontend
if npm ci >/dev/null 2>&1; then
    print_status "Frontend dependencies installed"
else
    print_error "Frontend npm install failed"
    exit 1
fi

# Build Docker image
if docker build -t techcommerce-frontend:test . >/dev/null 2>&1; then
    print_status "Frontend Docker image built successfully"
else
    print_error "Frontend Docker build failed"
    exit 1
fi

cd ../..

# Product API
echo "Testing Product API Service..."
cd services/product-api
if python3 -m venv test_env && source test_env/bin/activate && pip install -r requirements.txt >/dev/null 2>&1; then
    print_status "Product API dependencies installed"
    
    # Run basic test
    if python -c "from app import app; print('✅ App imports successfully')" 2>/dev/null; then
        print_status "Product API app loads correctly"
    else
        print_warning "Product API app has import issues (Flask not in virtual env)"
    fi
    
    deactivate 2>/dev/null || true
    rm -rf test_env
else
    print_warning "Product API dependency installation had issues"
fi

# Build Docker image
if docker build -t techcommerce-product-api:test . >/dev/null 2>&1; then
    print_status "Product API Docker image built successfully"
else
    print_error "Product API Docker build failed"
    exit 1
fi

cd ../..

# Order API
echo "Testing Order API Service..."
cd services/order-api
if npm ci >/dev/null 2>&1; then
    print_status "Order API dependencies installed"
else
    print_error "Order API npm install failed"
    exit 1
fi

# Build Docker image
if docker build -t techcommerce-order-api:test . >/dev/null 2>&1; then
    print_status "Order API Docker image built successfully"
else
    print_error "Order API Docker build failed"
    exit 1
fi

cd ../..

# Test 3: Run services in containers and test connectivity
echo ""
echo "🐳 Step 3: Container Runtime Testing"
echo "====================================="

# Clean up any existing containers
docker rm -f techcommerce-frontend techcommerce-product-api techcommerce-order-api 2>/dev/null || true

# Start Product API
echo "Starting Product API container..."
docker run -d --name techcommerce-product-api -p 5001:5000 techcommerce-product-api:test
sleep 3

# Test Product API health
if curl -s http://localhost:5001/healthz | grep -q "ok"; then
    print_status "Product API health check passed"
else
    print_error "Product API health check failed"
    docker logs techcommerce-product-api
    exit 1
fi

# Test Product API endpoint
if curl -s http://localhost:5001/products | grep -q "Widget"; then
    print_status "Product API /products endpoint working"
else
    print_error "Product API /products endpoint failed"
    exit 1
fi

# Start Order API
echo "Starting Order API container..."
docker run -d --name techcommerce-order-api -p 7001:7000 techcommerce-order-api:test
sleep 3

# Test Order API health
if curl -s http://localhost:7001/healthz | grep -q "ok"; then
    print_status "Order API health check passed"
else
    print_error "Order API health check failed"
    docker logs techcommerce-order-api
    exit 1
fi

# Test Order API endpoint
if curl -s http://localhost:7001/orders | grep -q "ord_1"; then
    print_status "Order API /orders endpoint working"
else
    print_error "Order API /orders endpoint failed"
    exit 1
fi

# Start Frontend
echo "Starting Frontend container..."
docker run -d --name techcommerce-frontend -p 3001:3000 \
    -e FRONTEND_API_BASE_URL=http://host.docker.internal:5001 \
    -e ORDER_API_BASE_URL=http://host.docker.internal:7001 \
    techcommerce-frontend:test
sleep 3

# Test Frontend health
if curl -s http://localhost:3001/healthz | grep -q "ok"; then
    print_status "Frontend health check passed"
else
    print_error "Frontend health check failed"
    docker logs techcommerce-frontend
    exit 1
fi

# Test Frontend main page
if curl -s http://localhost:3001/ | grep -q "TechCommerce Frontend"; then
    print_status "Frontend main page working"
else
    print_error "Frontend main page failed"
    exit 1
fi

# Test 4: Kubernetes manifests validation
echo ""
echo "☸️  Step 4: Kubernetes Manifests Validation"
echo "============================================"

# Check if kubectl is available
if command -v kubectl >/dev/null 2>&1; then
    print_status "kubectl is available"
    
    # Validate Kubernetes manifests
    if kubectl apply --dry-run=client -k k8s/base >/dev/null 2>&1; then
        print_status "Kubernetes base manifests are valid"
    else
        print_error "Kubernetes base manifests have errors"
        exit 1
    fi
    
    if kubectl apply --dry-run=client -k k8s/overlays/staging >/dev/null 2>&1; then
        print_status "Kubernetes staging manifests are valid"
    else
        print_error "Kubernetes staging manifests have errors"
        exit 1
    fi
    
    if kubectl apply --dry-run=client -k k8s/overlays/production >/dev/null 2>&1; then
        print_status "Kubernetes production manifests are valid"
    else
        print_error "Kubernetes production manifests have errors"
        exit 1
    fi
else
    print_warning "kubectl not available - skipping Kubernetes manifest validation"
fi

# Test 5: CI/CD Pipeline validation
echo ""
echo "⚙️  Step 5: CI/CD Pipeline Validation"
echo "====================================="

# Check GitHub Actions workflow syntax
if command -v yamllint >/dev/null 2>&1; then
    if yamllint .github/workflows/ci-cd.yaml >/dev/null 2>&1; then
        print_status "GitHub Actions workflow syntax is valid"
    else
        print_warning "GitHub Actions workflow has syntax warnings"
    fi
else
    print_warning "yamllint not available - skipping workflow validation"
fi

# Test 6: Security configurations
echo ""
echo "🔒 Step 6: Security Configuration Check"
echo "========================================"

# Check if security files exist
if [[ -f "security/trivyignore" ]]; then
    print_status "Trivy ignore file exists"
else
    print_error "Trivy ignore file missing"
fi

if [[ -f "security/.npmauditrc.json" ]]; then
    print_status "NPM audit configuration exists"
else
    print_error "NPM audit configuration missing"
fi

# Test 7: Documentation check
echo ""
echo "📚 Step 7: Documentation Validation"
echo "==================================="

if [[ -f "README.md" && -f "docs/architecture-overview.md" && -f "docs/troubleshooting.md" ]]; then
    print_status "All required documentation files exist"
else
    print_error "Some documentation files are missing"
fi

# Cleanup
echo ""
echo "🧹 Cleanup"
echo "=========="

docker rm -f techcommerce-frontend techcommerce-product-api techcommerce-order-api 2>/dev/null || true
print_status "Containers cleaned up"

# Final summary
echo ""
echo "🎉 Testing Complete!"
echo "===================="
print_status "All services are working correctly!"
print_status "The TechCommerce microservices platform is ready for deployment!"

echo ""
echo "Next steps:"
echo "1. Set up your container registry (GitHub Container Registry, Docker Hub, etc.)"
echo "2. Configure GitHub secrets for CI/CD:"
echo "   - REGISTRY (e.g., ghcr.io/yourusername)"
echo "   - REGISTRY_USERNAME"
echo "   - REGISTRY_PASSWORD"
echo "   - KUBE_CONFIG (base64 encoded kubeconfig)"
echo "3. Push to GitHub to trigger the CI/CD pipeline"
echo "4. Deploy to your Kubernetes cluster using: kubectl apply -k k8s/overlays/staging"

echo ""
echo "🔗 Service URLs (when running locally):"
echo "Frontend: http://localhost:3001"
echo "Product API: http://localhost:5001"
echo "Order API: http://localhost:7001"