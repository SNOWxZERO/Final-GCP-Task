# Final GCP DevOps Project - Development Journey

## Project Overview

This document chronicles the step-by-step development process of deploying a Python application on GCP using Terraform, GKE, and automated deployment scripts.

---

## Step 1: Application Investigation & Dockerization

### Creating the Dockerfile

First of all, I investigated the application and created the Dockerfile to build the image. Then, I added a Docker Compose configuration for the Redis service with the app image to test it locally.

**Docker Compose Test:**

```bash
docker-compose up --build
```

This allowed me to verify that the application worked correctly with Redis before deploying to GCP.

---

## Step 2: Initial Terraform Infrastructure

### Creating Basic Infrastructure

I created a simple Terraform configuration with the main components to make the infrastructure ready. This initial version can be found in:

```c
Terraform/main(normal-version-without-modules).tf.backup
```

This non-modular version included:

- VPC and subnets
- GKE cluster
- Management VM
- Artifact Registry
- Basic networking components

**Initial Deployment:**

```bash
cd Terraform
terraform init
terraform apply
```

---

## Step 3: Manual Setup & Discovery

### SSH into the Private VM

After the infrastructure was created, I SSH'd into the private VM to see what needed to be done:

```bash
gcloud compute ssh <vm-name> \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --project=<project-id>
```

### The Problem

I noticed we didn't have Docker, kubectl, or Git installed (or they weren't assigned to the user I SSH'd with - I don't really know now 😅).

### Manual Installation

What I did was install Docker, Git, and kubectl manually:

```bash
# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER

# Install kubectl
sudo apt-get install -y kubectl

# Install Git
sudo apt-get install -y git
```

---

## Step 4: Manual Deployment Process

### Building and Pushing the Image

Then I cloned the app repository, added the Dockerfile, built the image, and pushed it to the Artifact Registry:

```bash
# Clone the repository
git clone https://github.com/ahmedzak7/GCP-2025.git
cd GCP-2025/DevOps-Challenge-Demo-Code-master

# Configure Docker for Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build the image
docker build -t us-central1-docker.pkg.dev/<project-id>/<repo-name>/demo-app:latest .

# Push to Artifact Registry
docker push us-central1-docker.pkg.dev/<project-id>/<repo-name>/demo-app:latest
```

### Kubernetes Deployment

Then I made a deployment file with Redis, Redis service, app image, and a LoadBalancer:

```bash
# Get GKE credentials
gcloud container clusters get-credentials <cluster-name> \
  --region=us-central1 \
  --internal-ip

# Apply the deployment
kubectl apply -f deployment.yaml

# Check the service
kubectl get service demo-app-service
```

### Testing

Now I tested the app at the LoadBalancer IP and it worked! 🎉

```bash
curl http://<LOAD_BALANCER_IP>
```

---

## Step 5: Automation Time! 🚀

### Creating the Deployment Script

Time to automate! 😄

I created a script (`deploy.sh`) to do all the things on the VM instantly. I kept testing it until it worked perfectly.

**The script automates:**

1. Installing required tools
2. Cloning the repository
3. Building the Docker image
4. Pushing to Artifact Registry
5. Deploying to GKE
6. Creating the LoadBalancer service

---

## Step 6: Modularizing Terraform

### Restructuring the Configuration

Then I modularized the Terraform configuration into separate modules:

```c
modules/
├── networking/      # VPC, subnets, NAT, firewall rules
├── gke/            # GKE cluster, node pool, service account
├── compute/        # Management VM and service account
└── artifact-registry/  # Docker registry
```

### Adding Startup Script

I added a startup script (`StartupScript.sh`) for the VM to:

- Install main components (Docker, kubectl, Git, gcloud)
- Allow users to use them immediately
- Configure necessary permissions

### Deployment Automation

I added the deploy script as a null resource to work after the VM is ready:

```hcl
resource "null_resource" "deploy_app" {
  depends_on = [google_compute_instance.management_vm]
  
  provisioner "local-exec" {
    command = "..."
  }
}
```

---

## Step 7: Fixing Dependencies

### The Parallel Creation Problem

I also made the VM module dependent on the cluster because they were creating in parallel, and that caused a problem with the `local-exec` (the null resource) because the cluster wasn't ready for deployment yet.

**Solution:**

```hcl
module "compute" {
  source = "./modules/compute"
  
  depends_on = [module.gke]  # Wait for GKE cluster to be ready
  
  # ... other configurations
}
```

---

## Step 8: Success! :D

### Final Result

After a lot of trial and error, we got this working perfectly!

**Now you just:**

```bash
terraform apply
```

**And you get:**

- Complete infrastructure provisioned
- Application automatically deployed
- App ready on the LoadBalancer! 🎉

![Application Running Successfully]({88BBE6C5-AD76-42D3-9E5D-FF6B7E324134}.png)

---

## Lessons Learned

1. **Manual testing first** - Understanding the manual process before automating
2. **Dependencies matter** - Terraform resources need proper dependency management
3. **Startup scripts are powerful** - Automating VM configuration saves time
4. **Modular infrastructure** - Breaking down Terraform into modules improves maintainability
5. **Iterative development** - Testing and refining until everything works seamlessly

---

## Quick Deployment

To deploy this entire infrastructure from scratch:

```bash
# Navigate to Terraform directory
cd Terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy everything
terraform apply
```

Wait 15-20 minutes, and your application will be live on the LoadBalancer IP! ✨
