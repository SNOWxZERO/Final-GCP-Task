# GCP DevOps Challenge - Complete Infrastructure Setup

This solution creates a secure GCP infrastructure with private GKE cluster, Artifact Registry, and proper network isolation.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      VPC Network                        │
├──────────────────────┬──────────────────────────────────┤
│  Management Subnet   │    Restricted Subnet             │
│  ┌────────────────┐  │    ┌──────────────────────────┐  │
│  │                │  │    │  Private GKE Cluster     │  │
│  │  Private VM    │──┼───>│  - Private control plane │  │
│  │  (kubectl)     │  │    │  - Private nodes         │  │
│  │                │  │    │  - Custom SA             │  │
│  └────────────────┘  │    └──────────────────────────┘  │
│         │            │              │                   │
│    NAT Gateway       │         No Internet              │
│         │            │              │                   │
└─────────┼────────────┴──────────────┼───────────────────┘
          │                           │
          ▼                           ▼
      Internet                   Load Balancer
                                      │
                                      ▼
                                   Public
```

## Features Implemented

✅ Custom VPC with two subnets (management & restricted)  
✅ NAT Gateway only on management subnet  
✅ Private GKE cluster with private control plane  
✅ Authorized networks restricting access to management subnet  
✅ Custom service account for GKE nodes  
✅ Private Artifact Registry for Docker images  
✅ Private management VM with kubectl access  
✅ Public HTTP Load Balancer for application  
✅ No default service accounts used  
✅ Restricted subnet has no internet access  

## Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **Required APIs enabled**:

   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   gcloud services enable servicenetworking.googleapis.com
   ```

4. **Terraform** installed (v1.0+)
5. **gcloud CLI** installed and configured

## Setup Instructions

### Step 1: Prepare Terraform Files

1. Create a new directory for your project:

   ```bash
   mkdir gcp-devops-challenge
   cd gcp-devops-challenge
   ```

2. Create the following files:
   - `main.tf` - Main infrastructure configuration
   - `variables.tf` - Variable definitions
   - `outputs.tf` - Output values
   - `terraform.tfvars` - Your configuration values

3. Copy `terraform.tfvars.example` to `terraform.tfvars` and update:

   ```hcl
   project_id = "your-project-id"
   region     = "us-central1"
   zone       = "us-central1-a"
   ```

### Step 2: Deploy Infrastructure

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Review the plan:

   ```bash
   terraform plan
   ```

3. Apply the configuration:

   ```bash
   terraform apply
   ```

   Type `yes` when prompted.

4. Save the outputs:

   ```bash
   terraform output > outputs.txt
   ```

### Step 3: Connect to Management VM

Use IAP (Identity-Aware Proxy) to connect to the private VM:

```bash
gcloud compute ssh Gad-Final-Task-management-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --project=iti-project-476212
```

### Step 4: Build and Deploy Application

On the management VM:

1. Upload the deployment script:

   ```bash
   # From your local machine
   gcloud compute scp deploy.sh compute ssh Gad-Final-Task-management-vm:~/ \
     --zone=us-central1-a \
     --tunnel-through-iap \
     --project=iti-project-476212
   ```

2. Connect to the VM and run the script:

   ```bash
   # On the VM
   chmod +x deploy.sh
   
   # Edit the script to add your project ID
   nano deploy.sh
   
   # Run the deployment
   ./deploy.sh
   ```

The script will:

- Clone the application repository
- Build the Docker image
- Push to Artifact Registry
- Deploy to GKE
- Expose via Load Balancer

### Step 5: Access Your Application

After deployment completes, get the Load Balancer IP:

```bash
kubectl get service demo-app-service
```

Access your application at: `http://LOAD_BALANCER_IP`

## Manual Deployment Alternative

If you prefer to deploy manually instead of using the script:

```bash
# 1. Get GKE credentials
gcloud container clusters get-credentials devops-challenge-gke-cluster \
  --region=us-central1 \
  --internal-ip

# 2. Configure Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# 3. Clone and build
git clone https://github.com/ahmedzak7/GCP-2025.git
cd GCP-2025/DevOps-Challenge-Demo-Code-master

# 4. Create Dockerfile
cat > Dockerfile <<'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["python", "app.py"]
EOF

# 5. Build and push
IMAGE_URL="us-central1-docker.pkg.dev/YOUR_PROJECT_ID/devops-challenge-docker-repo/demo-app:latest"
docker build -t $IMAGE_URL .
docker push $IMAGE_URL

# 6. Deploy to Kubernetes
kubectl create deployment demo-app --image=$IMAGE_URL
kubectl expose deployment demo-app --type=LoadBalancer --port=80 --target-port=8080
```

## Network Security Details

### Management Subnet

- **CIDR**: 10.0.1.0/24
- **Internet**: ✅ Via NAT Gateway
- **Purpose**: Houses management VM for cluster access
- **Access**: SSH via IAP (35.235.240.0/20)

### Restricted Subnet

- **CIDR**: 10.0.2.0/24
- **Internet**: ❌ No internet access
- **Purpose**: Houses GKE cluster
- **Pods CIDR**: 10.1.0.0/16
- **Services CIDR**: 10.2.0.0/16

### GKE Cluster

- **Control Plane**: Private (172.16.0.0/28)
- **Nodes**: Private (no public IPs)
- **Authorized Networks**: Only management subnet (10.0.1.0/24)
- **Service Account**: Custom SA with minimal permissions

## Useful Commands

### Check GKE Status

```bash
kubectl get nodes
kubectl get pods -A
kubectl get services
```

### View Application Logs

```bash
kubectl logs -f deployment/demo-app
```

### Scale Application

```bash
kubectl scale deployment demo-app --replicas=5
```

### Update Application

```bash
# Build new image with new tag
docker build -t IMAGE_URL:v2 .
docker push IMAGE_URL:v2

# Update deployment
kubectl set image deployment/demo-app demo-app=IMAGE_URL:v2
```

### Check Artifact Registry

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/devops-challenge-docker-repo
```

## Cost Optimization

To reduce costs:

1. **Use preemptible nodes**:

   ```hcl
   use_preemptible_nodes = true
   ```

2. **Reduce node count**:

   ```hcl
   gke_node_count = 2
   ```

3. **Use smaller machine types**:

   ```hcl
   gke_machine_type = "e2-small"
   ```

4. **Delete when not in use**:

   ```bash
   terraform destroy
   ```

## Troubleshooting

### Can't connect to GKE cluster from VM

- Verify VM is in management subnet
- Check authorized networks configuration
- Ensure using `--internal-ip` flag

### Image pull errors

- Verify Artifact Registry permissions
- Check service account has `artifactregistry.reader` role
- Confirm image URL format

### Load Balancer not getting IP

- Wait 5-10 minutes for provisioning
- Check firewall rules allow health checks
- Verify service type is LoadBalancer

### VM can't reach internet

- Verify NAT gateway is configured
- Check Cloud Router is in the same region
- Confirm VM is in management subnet

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Security Best Practices Implemented

✅ Private GKE control plane  
✅ Private nodes with no public IPs  
✅ Custom service accounts with minimal permissions  
✅ No default service accounts  
✅ Restricted subnet isolated from internet  
✅ Authorized networks limiting cluster access  
✅ Private VM accessible only via IAP  
✅ Private Artifact Registry  
✅ Workload Identity enabled  

## References

- [GKE Private Clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Cloud NAT](https://cloud.google.com/nat/docs/overview)
- [IAP for TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)

## Support

For issues or questions:

1. Check Terraform outputs: `terraform output`
2. View GCP Console for resource status
3. Check application logs: `kubectl logs -f deployment/demo-app`
