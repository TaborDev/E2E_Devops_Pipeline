# Manual Testing Guide

## Quick Local Testing

### Option 1: Test Individual Services with Docker

1. **Build and test Product API:**
   ```bash
   cd services/product-api
   docker build -t product-api:test .
   docker run -d --name product-api -p 5001:5000 product-api:test
   
   # Test endpoints
   curl http://localhost:5001/healthz
   curl http://localhost:5001/products
   
   # Cleanup
   docker rm -f product-api
   ```

2. **Build and test Order API:**
   ```bash
   cd services/order-api
   docker build -t order-api:test .
   docker run -d --name order-api -p 7001:7000 order-api:test
   
   # Test endpoints
   curl http://localhost:7001/healthz
   curl http://localhost:7001/orders
   
   # Cleanup
   docker rm -f order-api
   ```

3. **Build and test Frontend:**
   ```bash
   cd services/frontend
   docker build -t frontend:test .
   docker run -d --name frontend -p 3001:3000 frontend:test
   
   # Test endpoints
   curl http://localhost:3001/healthz
   curl http://localhost:3001/
   
   # Cleanup
   docker rm -f frontend
   ```

### Option 2: Test with Node.js/Python directly

1. **Frontend:**
   ```bash
   cd services/frontend
   npm install
   npm start
   # Test: curl http://localhost:3000/healthz
   ```

2. **Product API:**
   ```bash
   cd services/product-api
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   python app.py
   # Test: curl http://localhost:5000/healthz
   ```

3. **Order API:**
   ```bash
   cd services/order-api
   npm install
   npm start
   # Test: curl http://localhost:7000/healthz
   ```

## Expected Responses

### Product API `/products`
```json
[
  {"id": 1, "name": "Widget", "price": 9.99},
  {"id": 2, "name": "Gadget", "price": 14.99}
]
```

### Order API `/orders`
```json
[{"id": "ord_1", "total": 24.99}]
```

### Health Checks
```json
{"status": "ok"}
{"live": true}
```