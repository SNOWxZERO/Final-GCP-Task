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

if [ -d "DevOps-Challenge-Demo-Code-With-Docker-Ready" ]; then
    rm -rf DevOps-Challenge-Demo-Code-With-Docker-Ready
fi

git clone https://github.com/SNOWxZERO/DevOps-Challenge-Demo-Code-With-Docker-Ready.git 

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

# Step 7: Deployment manifest should already exist, just verify
echo -e "\n${YELLOW}Step 7: Verifying deployment manifest...${NC}"
if [ ! -f "deployment.yaml" ]; then
    echo -e "${RED}Error: Deployment manifest not found!${NC}"
    exit 1
else
    echo "Deployment manifest found"
fi

# Step 8: Deploy to GKE
echo -e "\n${YELLOW}Step 8: Deploying to GKE...${NC}"
# Replace IMAGE_URL placeholder with actual image URL (already set in Step 4)
echo "Substituting image: ${IMAGE_URL}"
if [ -z "${IMAGE_URL}" ]; then
    echo -e "${RED}ERROR: IMAGE_URL is not set!${NC}"
    exit 1
fi
sed "s|\${IMAGE_URL}|${IMAGE_URL}|g" deployment.yaml | kubectl apply -f -

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
    echo -e "\n${GREEN}======================================== ${NC}"
    echo -e "${GREEN} Application is accessible at:${NC}"
    echo -e "${GREEN} http://$LB_IP${NC}"
    echo -e "${GREEN} ======================================== ${NC}"
else
    echo -e "\n${YELLOW} Load Balancer IP not yet assigned. Run this command to check:${NC}"
    echo "kubectl get service demo-app-service"
fi

echo -e "\n${GREEN}Useful commands:${NC}"
echo "  View logs:    kubectl logs -f deployment/demo-app"
echo "  Scale app:    kubectl scale deployment demo-app --replicas=5"
echo "  Delete app:   kubectl delete -f deployment.yaml"