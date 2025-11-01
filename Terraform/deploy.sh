#!/bin/bash

# Build and Deploy Script for GCP DevOps Challenge
# Run this script from the management VM

set -e

# Configuration
PROJECT_ID="iti-project-476212"
REGION="us-central1"
REPO_NAME="gad-final-task-docker-repo"
IMAGE_NAME="demo-app"
IMAGE_TAG="latest"
CLUSTER_NAME="gad-final-task-gke-cluster"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GCP DevOps Challenge Deployment ===${NC}"

# Step 1: Clone the repository
echo -e "\n${YELLOW}Step 1: Cloning repository...${NC}"
if [ ! -d "GCP-2025" ]; then
    git clone https://github.com/SNOWxZERO/DevOps-Challenge-Demo-Code-With-Docker-Ready.git
fi
cd DevOps-Challenge-Demo-Code-With-Docker-Ready

# Step 2: Dockerfile should already exist, just verify
echo -e "\n${YELLOW}Step 2: Verifying Dockerfile...${NC}"
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found!${NC}"
    exit 1
else
    echo "Dockerfile found"
fi

# Step 3: Configure Docker for Artifact Registry
echo -e "\n${YELLOW}Step 3: Configuring Docker for Artifact Registry...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# Step 4: Build the Docker image
echo -e "\n${YELLOW}Step 4: Building Docker image...${NC}"
IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t ${IMAGE_URL} .

# Step 5: Push to Artifact Registry
echo -e "\n${YELLOW}Step 5: Pushing image to Artifact Registry...${NC}"
docker push ${IMAGE_URL}

# Step 6: Get GKE credentials
echo -e "\n${YELLOW}Step 6: Getting GKE credentials...${NC}"
gcloud container clusters get-credentials ${CLUSTER_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --internal-ip

# Step 7: Create Kubernetes deployment manifest
echo -e "\n${YELLOW}Step 7: Creating Kubernetes manifests...${NC}"
cat > deployment.yaml <<EOF
---
# Redis Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: default
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
          name: redis
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
# Redis Service
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
    protocol: TCP
    name: redis
---
# Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: default
  labels:
    app: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: ${IMAGE_URL}
        ports:
        - containerPort: 8888
          name: http
        env:
        - name: PORT
          value: "8888"
        - name: HOST
          value: "0.0.0.0"
        - name: ENVIRONMENT
          value: "PRODUCTION"
        - name: REDIS_HOST
          value: "redis"
        - name: REDIS_PORT
          value: "6379"
        - name: REDIS_DB
          value: "0"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 8888
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8888
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app-service
  namespace: default
  labels:
    app: demo-app
spec:
  type: LoadBalancer
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 8888
    protocol: TCP
    name: http
EOF

# Step 8: Deploy to GKE
echo -e "\n${YELLOW}Step 8: Deploying to GKE...${NC}"
kubectl apply -f deployment.yaml

# Step 9: Wait for deployment
echo -e "\n${YELLOW}Step 9: Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/demo-app --timeout=5m

# Step 10: Get Load Balancer IP
echo -e "\n${YELLOW}Step 10: Getting Load Balancer IP...${NC}"
echo "Waiting for Load Balancer IP to be assigned..."
for i in {1..30}; do
    LB_IP=$(kubectl get service demo-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$LB_IP" ]; then
        break
    fi
    echo "Still waiting... ($i/30)"
    sleep 10
done

# Display results
echo -e "\n${GREEN}=== Deployment Complete! ===${NC}"
echo -e "\n${GREEN}Deployment Status:${NC}"
kubectl get deployments
echo -e "\n${GREEN}Pods:${NC}"
kubectl get pods
echo -e "\n${GREEN}Service:${NC}"
kubectl get service demo-app-service

if [ -n "$LB_IP" ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Application is accessible at:${NC}"
    echo -e "${GREEN}http://$LB_IP${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "\n${YELLOW}Load Balancer IP not yet assigned. Run this command to check:${NC}"
    echo "kubectl get service demo-app-service"
fi

echo -e "\n${GREEN}Useful commands:${NC}"
echo "  View logs:    kubectl logs -f deployment/demo-app"
echo "  Scale app:    kubectl scale deployment demo-app --replicas=5"
echo "  Delete app:   kubectl delete -f deployment.yaml"