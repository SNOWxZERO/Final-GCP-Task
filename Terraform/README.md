# GCP DevOps Challenge - Complete Infrastructure Setup

## 🎯 Overview

This project provisions a **production-ready GCP infrastructure** using modular Terraform configuration, featuring a private GKE cluster, Artifact Registry, and proper network isolation with automated application deployment.

## 🏗️ Architecture

```c
┌──────────────────────────────────────────────────────────────┐
│                         VPC Network                          │
├───────────────────────┬──────────────────────────────────────┤
│  Management Subnet    │       Restricted Subnet              │
│  (10.0.1.0/24)        │       (10.0.2.0/24)                  │
│  ┌─────────────────┐  │  ┌────────────────────────────────┐  │
│  │  Private VM     │  │  │  Private GKE Cluster           │  │
│  │  - kubectl      │──┼─>│  - Private control plane       │  │
│  │  - gcloud       │  │  │  - Private nodes (3x e2-medium)│  │
│  │  - docker       │  │  │  - Workload Identity           │  │
│  └─────────────────┘  │  └────────────────────────────────┘  │
│          │            │              │                       │
│    Cloud NAT          │         No Internet                  │
│          │            │              │                       │
└──────────┼────────────┴──────────────┼───────────────────────┘
           │                           │
           ▼                           ▼
       Internet                  Load Balancer
                                      │
                                      ▼
                                  Public Access
```

### Modular Structure

```c
Terraform/
├── main.tf                    # Root module orchestrating all components
├── variables.tf               # Variable definitions
├── terraform.tfvars          # Configuration values (DO NOT COMMIT)
├── output.tf                 # Infrastructure outputs
└── modules/
    ├── networking/           # VPC, subnets, NAT, firewall rules
    ├── gke/                  # GKE cluster, node pool, service account
    ├── compute/              # Management VM and automated deployment
    └── artifact-registry/    # Docker registry
```

## ✨ Features Implemented

✅ **Modular Terraform Configuration** - Reusable, maintainable modules  
✅ **Custom VPC** - Two subnets (management & restricted)  
✅ **Cloud NAT Gateway** - Only on management subnet  
✅ **Private GKE Cluster** - Private control plane & nodes  
✅ **Authorized Networks** - Restricts cluster access to management subnet  
✅ **Custom Service Accounts** - Least privilege IAM permissions  
✅ **Private Artifact Registry** - Docker image repository  
✅ **Private Management VM** - IAP access only, no external IP  
✅ **Automated Deployment** - Application deploys automatically via startup script  
✅ **Load Balancer** - Public HTTP access to application  
✅ **Workload Identity** - Secure pod authentication  
✅ **Network Isolation** - Restricted subnet has no internet access  

## 📦 Infrastructure Components

### 1. Networking Module

- **VPC Network** with custom subnets
- **Management Subnet** (10.0.1.0/24) - NAT enabled for outbound internet
- **Restricted Subnet** (10.0.2.0/24) - No internet access, GKE only
- **Cloud Router & NAT** - Managed outbound connectivity
- **Firewall Rules** - IAP SSH, internal communication, health checks
- **Secondary IP Ranges** - Pods (10.1.0.0/16), Services (10.2.0.0/16)

### 2. GKE Module

- **Private GKE Cluster** - No public endpoints
- **Node Pool** - 3x e2-medium instances (configurable)
- **Service Account** - Custom SA with minimal permissions
- **Workload Identity** - Enabled for secure pod authentication
- **Master CIDR** - 172.16.0.0/28 for control plane
- **Authorized Networks** - Management subnet only

### 3. Compute Module

- **Management VM** - e2-medium instance in management subnet
- **Service Account** - container.developer & artifactregistry.writer roles
- **Startup Script** - Installs kubectl, gcloud, docker, git
- **Automated Deployment** - Clones app, builds image, deploys to GKE
- **IAP Access** - No external IP, secure tunneling

### 4. Artifact Registry Module

- **Docker Repository** - Regional storage in us-central1
- **Private Access** - No public endpoints
- **Integration** - Direct GKE node pool access

## 📋 Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **Terraform** installed (v1.0+)
4. **gcloud CLI** installed and authenticated:

   ```bash
   gcloud auth application-default login
   ```

5. **Required GCP APIs** enabled:

   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   gcloud services enable servicenetworking.googleapis.com
   gcloud services enable iam.googleapis.com
   ```

## 🚀 Quick Start

### Step 1: Configure Variables

Create or edit `terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
prefix     = "your-prefix"  # Must be lowercase

# Network configuration
management_subnet_cidr = "10.0.1.0/24"
restricted_subnet_cidr = "10.0.2.0/24"
gke_pods_cidr          = "10.1.0.0/16"
gke_services_cidr      = "10.2.0.0/16"
gke_master_cidr        = "172.16.0.0/28"

# GKE configuration
gke_machine_type       = "e2-medium"
gke_node_count         = 3
gke_node_disk_size_gb  = 50
use_preemptible_nodes  = false

# VM configuration
vm_machine_type = "e2-medium"
```

**⚠️ Important:** Add `terraform.tfvars` to `.gitignore` - never commit sensitive values!

### Step 2: Initialize Terraform

```bash
cd Terraform
terraform init
```

This downloads the Google Cloud provider and initializes all modules.

### Step 3: Review Plan

```bash
terraform plan
```

Review all resources that will be created. Expected resources:

- 1 VPC with 2 subnets
- 1 Cloud Router + NAT Gateway
- 4 Firewall rules
- 1 Private GKE cluster with node pool
- 1 Management VM with startup script
- 1 Artifact Registry repository
- 2 Custom service accounts with IAM bindings

### Step 4: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately **15-20 minutes**.

The startup script on the management VM will automatically:

1. Install required tools (kubectl, docker, git, gcloud)
2. Clone application repository
3. Build Docker image
4. Push to Artifact Registry
5. Deploy to GKE cluster
6. Create LoadBalancer service

### Step 5: Get Infrastructure Details

```bash
terraform output
```

Save outputs for later use:

```bash
terraform output > infrastructure-details.txt
```

## 🔌 Accessing Your Infrastructure

### Connect to Management VM

Use IAP (Identity-Aware Proxy) tunnel - no external IP required:

```bash
gcloud compute ssh <vm-name> \
  --zone=<your-zone> \
  --tunnel-through-iap \
  --project=<your-project-id>
```

Replace `<vm-name>`, `<your-zone>`, and `<your-project-id>` with values from `terraform output`.

### Get GKE Credentials

From the management VM, configure kubectl:

```bash
gcloud container clusters get-credentials <cluster-name> \
  --region=<your-region> \
  --project=<your-project-id> \
  --internal-ip
```

**Important:** Use `--internal-ip` flag for private cluster access.

### Check Deployment Status

```bash
# View all resources
kubectl get all

# Check pod status
kubectl get pods -o wide

# Get LoadBalancer IP
kubectl get service demo-app-service

# View application logs
kubectl logs -l app=demo-app -f
```

### Access Your Application

Get the LoadBalancer external IP:

```bash
kubectl get service demo-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Access your application: `http://<LOAD_BALANCER_IP>`

Test the application:

```bash
# Single request
curl http://<LOAD_BALANCER_IP>

# Multiple requests to see counter increment
for i in {1..5}; do 
  echo "=== Request $i ==="
  curl -s http://<LOAD_BALANCER_IP> | grep -E "(Counter|PRODUCTION)"
  sleep 1
done
```

## 📝 Application Details

**Docker Image:** `<region>-docker.pkg.dev/<project-id>/<repo-name>/demo-app:latest`

**Technology Stack:**

- Python 3.8
- Tornado Web Framework
- Redis for state management
- Docker containerized

**Deployment Configuration:**

- 3 replicas for high availability
- Health checks (liveness & readiness probes)
- Resource limits configured
- LoadBalancer service type

## 🔧 Management Commands

### Scale Application

```bash
# Scale up
kubectl scale deployment demo-app --replicas=5

# Scale down
kubectl scale deployment demo-app --replicas=2
```

### Update Application

```bash
# Build new version
docker build -t <image-url>:v2 .

# Push to registry
docker push <image-url>:v2

# Update deployment
kubectl set image deployment/demo-app demo-app=<image-url>:v2

# Watch rollout
kubectl rollout status deployment/demo-app
```

### Monitor Resources

```bash
# View logs
kubectl logs -f deployment/demo-app

# Check resource usage
kubectl top pods
kubectl top nodes

# Watch pod status
kubectl get pods -w
```

### View Artifact Registry Images

```bash
gcloud artifacts docker images list \
  <region>-docker.pkg.dev/<project-id>/<repo-name>
```

## 🔐 Security Architecture

### Network Isolation

#### Management Subnet (10.0.1.0/24)

- ✅ Internet access via Cloud NAT (outbound only)
- ✅ Houses management VM
- ✅ IAP SSH access (35.235.240.0/20)
- ✅ Can communicate with restricted subnet

#### Restricted Subnet (10.0.2.0/24)

- ❌ No internet access
- ✅ Houses GKE cluster
- ✅ Pods CIDR: 10.1.0.0/16
- ✅ Services CIDR: 10.2.0.0/16

### GKE Security

- **Control Plane**: Private endpoint (172.16.0.0/28)
- **Nodes**: Private IPs only, no external access
- **Authorized Networks**: Management subnet only
- **Service Account**: Custom SA with minimal IAM roles
- **Workload Identity**: Enabled for secure pod authentication

### IAM & Service Accounts

**GKE Node Service Account:**

- `roles/logging.logWriter`
- `roles/monitoring.metricWriter`
- `roles/artifactregistry.reader`

**Management VM Service Account:**

- `roles/container.developer`
- `roles/artifactregistry.writer`

### Firewall Rules

1. **IAP SSH** - Allow IAP tunneling to management subnet
2. **Internal** - Allow all internal VPC communication
3. **Health Checks** - Allow GCP health check ranges
4. **LoadBalancer** - Allow ingress to GKE services

## 🔄 Module Dependencies

```c
networking (independent)
    ↓
    ├─> gke (depends on: vpc_name, restricted_subnet_name)
    ├─> compute (depends on: vpc_name, management_subnet_name)
    └─> artifact_registry (independent)
```

## 💰 Cost Optimization

### Recommended Cost-Saving Strategies

**1. Use Preemptible Nodes** (up to 80% savings):

```hcl
use_preemptible_nodes = true
```

**2. Reduce Node Count** (minimum for HA):

```hcl
gke_node_count = 2
```

**3. Use Smaller Machine Types**:

```hcl
gke_machine_type = "e2-small"  # Instead of e2-medium
```

**4. Regional vs Zonal Cluster**:

- Use zonal cluster for dev/test environments
- Regional cluster for production HA

**5. Destroy When Not In Use**:

```bash
terraform destroy  # Stops all billing
```

### Estimated Monthly Costs

| Component | Configuration | Estimated Cost |
|-----------|--------------|----------------|
| GKE Cluster | 3x e2-medium nodes | ~$73/month |
| Management VM | 1x e2-medium | ~$24/month |
| Cloud NAT | Standard usage | ~$45/month |
| Artifact Registry | <10GB storage | ~$0.10/month |
| Load Balancer | Standard | ~$18/month |
| **Total** | | **~$160/month** |

**With optimizations (preemptible + e2-small):** ~$40-50/month

## 🐛 Troubleshooting

### Common Issues & Solutions

#### ❌ Can't Connect to GKE Cluster from VM

**Problem:** `Unable to connect to the server`

**Solutions:**

- Verify VM is in management subnet: `gcloud compute instances describe <vm-name> --zone=<zone> --format="get(networkInterfaces[0].subnetwork)"`
- Check authorized networks include management subnet
- Always use `--internal-ip` flag when getting credentials
- Ensure GKE cluster has private endpoint enabled

#### ❌ Image Pull Errors in Kubernetes

**Problem:** `ErrImagePull` or `ImagePullBackOff`

**Solutions:**

- Verify Artifact Registry permissions:

  ```bash
  gcloud artifacts repositories get-iam-policy <repo-name> \
    --location=<region> --project=<project-id>
  ```

- Check GKE service account has `artifactregistry.reader` role
- Confirm image URL format: `<region>-docker.pkg.dev/<project>/<repo>/<image>:<tag>`
- Verify image exists: `gcloud artifacts docker images list <repo-url>`

#### ❌ LoadBalancer Not Getting External IP

**Problem:** Service stuck in `<pending>` state

**Solutions:**

- Wait 5-10 minutes for provisioning (can be slow)
- Check firewall rules allow health checks (130.211.0.0/22, 35.191.0.0/16)
- Verify service type is `LoadBalancer`
- Check GKE node pool has external connectivity via NAT

#### ❌ VM Can't Reach Internet

**Problem:** `curl: (6) Could not resolve host`

**Solutions:**

- Verify Cloud NAT is configured on management subnet
- Check Cloud Router is in the same region as VPC
- Confirm VM is in management subnet (not restricted)
- Test: `curl -I https://www.google.com`

#### ❌ Terraform Module Not Found

**Problem:** `Module not installed`

**Solutions:**

- Run `terraform init` to download/initialize modules
- Check module source paths in `main.tf`
- Verify module directories exist

#### ❌ Quota Exceeded Errors

**Problem:** `Quota '...' exceeded`

**Solutions:**

- Check quotas in GCP Console → IAM → Quotas
- Request quota increase if needed
- Reduce `gke_node_count` or use smaller `gke_machine_type`
- Use `pd-standard` instead of SSD disks

## 🧹 Cleanup & Destruction

### Destroy All Resources

```bash
cd Terraform
terraform destroy
```

Type `yes` when prompted. This will:

- Delete GKE cluster and node pool
- Remove management VM
- Delete Artifact Registry repository
- Remove VPC, subnets, NAT gateway
- Delete service accounts and IAM bindings

**⚠️ Warning:** This action is **irreversible** and will permanently delete all infrastructure.

### Selective Destruction

To remove specific modules:

```bash
# Destroy only GKE cluster
terraform destroy -target=module.gke

# Destroy only management VM
terraform destroy -target=module.compute
```

### Cost Considerations

Always destroy resources when not in use to avoid unnecessary charges:

- GKE clusters incur hourly charges
- NAT Gateway charges per hour + data processing
- Persistent disks charge for storage even when VMs are stopped

## 📦 What Gets Created

When you run `terraform apply`, the following resources are provisioned:

| Resource Type | Count | Purpose |
|--------------|-------|---------|
| VPC Network | 1 | Custom network with private subnets |
| Subnets | 2 | Management (NAT) + Restricted (GKE) |
| Cloud Router | 1 | Manages Cloud NAT |
| Cloud NAT Gateway | 1 | Outbound internet for management subnet |
| Firewall Rules | 4 | IAP SSH, internal, health checks, LB |
| GKE Cluster | 1 | Private Kubernetes cluster |
| GKE Node Pool | 1 | 3 worker nodes (configurable) |
| Compute Instance | 1 | Private management VM |
| Artifact Registry | 1 | Docker image repository |
| Service Accounts | 2 | GKE nodes + Management VM |
| IAM Bindings | ~6 | Least privilege permissions |

**Total Resources:** ~20-25 resources

## 🤝 Contributing

Suggestions for improvements:

1. **Remote State Management** - Use GCS backend for team collaboration
2. **CI/CD Integration** - Automate deployments with Cloud Build
3. **Monitoring Module** - Add Cloud Monitoring and Alerting
4. **Backup Module** - Implement automated backups
5. **Multi-Region** - Add disaster recovery capabilities

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 📞 Support

For issues or questions:

1. **Check Terraform Outputs:** `terraform output`
2. **View GCP Console:** Check resource status visually
3. **Check Application Logs:** `kubectl logs -f deployment/demo-app`
4. **Verify Infrastructure:** `gcloud compute instances list`
5. **Review this README:** Most common issues are documented above

---

**Project Status:** ✅ Production-Ready  
**Last Updated:** November 2025  
**Terraform Version:** >= 1.0  
**GCP Provider Version:** >= 4.0  

🚀 **Happy Cloud Computing!**
