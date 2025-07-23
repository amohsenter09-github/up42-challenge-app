# Minimal Terraform Infrastructure for UP42 Challenge

This directory contains a minimal Terraform configuration for deploying the AWS infrastructure required for the UP42 Challenge application. This is optimized for test/demo purposes with reduced costs and deployed in Ireland (eu-west-1).

## Architecture

The minimal Terraform configuration creates:

- **EKS Cluster**: Single-node Kubernetes cluster with t3.medium instances (17 pods capacity)
- **VPC**: Basic network environment with 2 AZs
- **EBS CSI Driver**: IAM roles and policies for persistent storage
- **ALB Controller**: IAM roles for load balancer management
- **Terraform State Bucket**: S3 bucket for remote state management
- **Minimal Security**: Basic security groups and access rules

**Note**: No S3 bucket for application data - MinIO provides S3-compatible storage

## File Structure

```
terraform/
├── main.tf                    # Main infrastructure (EKS, VPC, S3)
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── versions.tf                # Provider versions
├── providers.tf               # Provider configurations
├── backend.tf                 # Terraform backend configuration
├── deploy.sh                  # Automated deployment script
├── install-alb-controller.sh  # ALB Controller installation script
├── alb-controller-policy.json # IAM policy for ALB Controller
├── bootstrap.sh               # S3 backend bootstrap script
├── terraform.tfvars           # Variable values
└── README.md                  # This file
```

### Deployment Phases

- **Phase 1** (`main.tf`): EKS cluster, VPC, IAM roles
- **Phase 2** (`install-alb-controller.sh`): ALB Controller via Helm (requires EKS to be ready)
- **Phase 3**: EBS CSI Driver installation (post-deployment)

## Prerequisites

1. **AWS CLI** configured with admin access
2. **Terraform** 1.0 or later installed
3. **kubectl** installed
4. **helm** installed
5. **eksctl** installed (for ALB Controller setup)
6. **AWS Permissions**: Basic EKS, VPC, and S3 permissions

## Quick Start

### 1. Bootstrap S3 Backend (One-time setup)

First, create the S3 bucket for Terraform state:

```bash
cd terraform
chmod +x bootstrap.sh
./bootstrap.sh
```

This will:
- Create an S3 bucket for Terraform state
- Enable versioning and encryption
- Generate a `backend.tf` file with the bucket details

### 2. Configure Variables

Copy the example configuration file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if needed (defaults are suitable for testing).

### 3. Deploy Infrastructure (Two-Phase Deployment)

#### Option A: Automated Deployment (Recommended)
Use the deployment script for a guided experience:

```bash
chmod +x deploy.sh
./deploy.sh
```

This script will:
- Deploy the EKS cluster and basic infrastructure
- Wait for the cluster to be ready
- Configure kubectl automatically
- Optionally deploy the ALB Controller

#### Option B: Manual Deployment

**Phase 1: Deploy EKS Infrastructure**
```bash
terraform init
terraform plan
terraform apply
```

**Phase 2: Deploy ALB Controller (Optional)**
After the EKS cluster is ready:

```bash
# Configure kubectl
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)

# Deploy ALB Controller
chmod +x install-alb-controller.sh
./install-alb-controller.sh
```

### 4. Verify Deployment

```bash
# Check cluster status
kubectl get nodes

# Check ALB Controller (if deployed)
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Configuration

### Minimal Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `eu-west-1` (Ireland) |
| `cluster_name` | Name of the EKS cluster | `up42-challenge` |
| `cluster_version` | Kubernetes version | `1.28` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |

### Resource Specifications

- **EKS Cluster**: 1.28 Kubernetes version
- **Node Group**: t3.medium instances (1-2 nodes, 17 pods capacity each)
- **VPC**: 2 availability zones in Ireland
- **NAT Gateway**: Single gateway for cost optimization
- **EBS CSI Driver**: IAM roles for dynamic volume provisioning
- **ALB Controller**: IAM roles for load balancer management
- **State Management**: S3 backend with versioning and encryption

## State Management

This configuration uses **S3 backend** for Terraform state management:

- **Remote State**: Stored in S3 bucket with versioning
- **Encryption**: Server-side encryption enabled
- **Security**: Public access blocked
- **No Locking**: Simplified setup without DynamoDB

### State Bucket Details

The bootstrap script creates:
- S3 bucket: `up42-challenge-terraform-state-<random>`
- Versioning enabled
- Encryption enabled
- Public access blocked

## Cost Optimization

This minimal configuration is designed for cost efficiency:

- **t3.medium instances**: ~$30/month per node (upgraded for better pod capacity)
- **Single NAT Gateway**: ~$45/month
- **2 AZs**: Minimal redundancy
- **1-2 nodes**: Auto-scaling based on demand
- **S3 State Storage**: ~$0.023/GB/month
- **EBS Volumes**: ~$0.10/GB/month (for MinIO storage)

**Estimated monthly cost**: ~$75-90 USD

**Note**: t3.medium provides 17 pods capacity vs 11 pods on t3.small, preventing "Too many pods" issues

## Outputs

After deployment, you'll get:

- `cluster_id`: EKS cluster ID
- `cluster_endpoint`: EKS control plane endpoint
- `vpc_id`: VPC ID
- `private_subnets`: Private subnet IDs
- `public_subnets`: Public subnet IDs
- `terraform_state_bucket`: State bucket name
- `kubeconfig_command`: kubectl configuration command

**Note**: No S3 bucket output - MinIO provides application storage

## Scaling and Cost Management

### Scale Down (Stop Cluster)
To stop the cluster and save costs without destroying infrastructure:

```bash
# Edit main.tf to scale down node group
# Change the node group configuration:
eks_managed_node_groups = {
  general = {
    name = "general-node-group"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size     = 0  # Scale down to 0
    max_size     = 1  # Keep at 1 (EKS requirement)
    desired_size = 0  # Scale down to 0 instances
    disk_size = 20
    labels = {
      Environment = "production"
      NodeGroup   = "general"
    }
  }
}

# Apply the changes
terraform apply
```

**Result**: 
- ✅ No EC2 instances running = No compute costs (~$30/month savings)
- ✅ ALB deleted = No load balancer costs (~$20/month savings)
- ✅ EBS volumes terminated = No storage costs (~$5/month savings)
- ✅ EKS cluster preserved = Easy to restart
- ✅ Total savings: ~$55/month

### Scale Up (Restart Cluster)
To restart the cluster:

```bash
# Edit main.tf to scale up node group
# Change the node group configuration:
eks_managed_node_groups = {
  general = {
    name = "general-node-group"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size     = 1  # Scale back to 1
    max_size     = 2  # Scale back to 2
    desired_size = 1  # Scale back to 1 instance
    disk_size = 20
    labels = {
      Environment = "production"
      NodeGroup   = "general"
    }
  }
}

# Apply the changes
terraform apply
```

**Result**:
- ✅ EC2 instances start up
- ✅ ALB is recreated
- ✅ EBS volumes are provisioned
- ✅ Applications can be redeployed

### Quick Scaling Commands
```bash
# Scale down (stop cluster)
sed -i '' 's/desired_size = 1/desired_size = 0/' main.tf
sed -i '' 's/min_size     = 1/min_size     = 0/' main.tf
terraform apply

# Scale up (start cluster)
sed -i '' 's/desired_size = 0/desired_size = 1/' main.tf
sed -i '' 's/min_size     = 0/min_size     = 1/' main.tf
terraform apply
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: The S3 state bucket will remain and needs to be deleted manually if desired.

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**
   ```bash
   aws sts get-caller-identity
   ```

2. **Instance Type Availability**
   - t3.medium should be available in Ireland region
   - If not, change to t3.small or t2.medium

3. **VPC CIDR Conflicts**
   - Change vpc_cidr in terraform.tfvars if needed

4. **State Backend Issues**
   - Ensure the bootstrap script ran successfully
   - Check S3 bucket exists and is accessible
   - Verify backend.tf file was created

5. **Pod Capacity Issues**
   - t3.medium provides 17 pods vs 11 on t3.small
   - Upgrade instance type if hitting pod limits

### Useful Commands

```bash
# Check cluster status
kubectl get nodes

# Check cluster info
aws eks describe-cluster --name up42-challenge --region eu-west-1

# List outputs
terraform output

# Check state
terraform show

# Check EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi

# Check ALB Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check node pod capacity
kubectl describe node | grep -A 5 "Allocated resources"
```

## Next Steps

After deploying the infrastructure:

1. **Install EBS CSI Driver**:
   ```bash
   kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28"
   ```

2. **Deploy MinIO**:
   ```bash
   helm repo add minio https://charts.bitnami.com/minio
   helm install minio minio/minio \
     --set auth.rootUser=minioadmin \
     --set auth.rootPassword=minioadmin123 \
     --set persistence.size=10Gi
   ```

3. **Deploy s3www application**:
   ```bash
   helm install s3www-app helm/s3www-app -f helm/s3www-app/values-custom.yaml
   ```

4. **Test the application**

See the main project README for detailed application deployment instructions. 