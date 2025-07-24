# UP42 Senior Cloud Engineer Challenge - Complete Implementation

A production-ready Kubernetes deployment solution for the [s3www application](https://github.com/harshavardhana/s3www) with [MinIO](https://min.io/) dependency, deployed on AWS EKS using Helm charts and Terraform.

## 📚 Documentation

- **[🚀 Quick Start](QUICKSTART.md)** - Get up and running in 10 minutes
- **[🏗️ Architecture](ARCHITECTURE.md)** - Detailed system architecture
- **[🔧 Deployment Guide](terraform/DEPLOYMENT.md)** - Terraform infrastructure deployment
- **[📦 Helm Chart](helm/s3www-app/CHART.md)** - Application deployment details
- **[🎯 Design Decisions](DESIGN.md)** - Implementation rationale and trade-offs
- **[🤝 Contributing](CONTRIBUTING.md)** - How to contribute to the project

## 🎯 Challenge Overview
Deploy a lightweight Go web server (`s3www`) that serves static files from S3-compatible storage (`MinIO`) with external access via AWS Application Load Balancer.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS EKS       │    │   MinIO         │    │   AWS ALB       │
│   Cluster       │    │   (S3 Compatible│    │   LoadBalancer  │
│   (t3.medium)   │    │   Storage)      │    │   Service       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   s3www App     │◄──►│   MinIO         │    │   External      │
│   (Go Web       │    │   (EBS Storage) │    │   Access        │
│   Server)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Complete Implementation Guide

### 1. Prerequisites
```bash
# Install required tools
brew install terraform kubectl helm awscli

# Configure AWS credentials
aws configure

# Verify installations
terraform --version
kubectl version --client
helm version
```

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Key Infrastructure Components:**
- VPC with public/private subnets across 2 AZs
- EKS cluster with t3.medium nodes (17 pods capacity)
- EBS CSI Driver IAM roles and policies
- ALB Ingress Controller setup

### 3. Install EBS CSI Driver
```bash
# Install EBS CSI Driver for persistent storage
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28"

# Verify installation
kubectl get pods -n kube-system | grep ebs-csi
```

### 4. Deploy MinIO
```bash
helm repo add minio https://charts.bitnami.com/minio
helm install minio minio/minio \
  --set auth.rootUser=minioadmin \
  --set auth.rootPassword=minioadmin123 \
  --set persistence.size=10Gi \
  --set persistence.storageClass=ebs-sc

# Wait for MinIO to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=minio --timeout=300s
```

**Note**: For production, use AWS Secrets Manager for credentials instead of hardcoded values.

### 5. Deploy s3www Application
```bash
helm install s3www-app helm/s3www-app -f helm/s3www-app/values-custom.yaml

# Wait for s3www to be ready
kubectl wait --for=condition=ready pod -l app=s3www-app --timeout=300s
```

## 🔧 Configuration

### MinIO Setup
1. **Access Console**: 
   ```bash
   kubectl port-forward -n default svc/minio-console 9090:9090 --address 0.0.0.0
   ```
2. **Login**: `http://localhost:9090` (minioadmin / minioadmin123) <!-- Development credentials - use AWS Secrets Manager in production -->
3. **Create Bucket**: `s3www-storage`
4. **Upload Files**: Add HTML, CSS, images, etc.

### Automatic File Upload (Optional)
The init job automatically runs on deployment and can fetch and upload files:

```bash
# Edit environment configuration
nano terraform/environments/dev.tfvars

# Enable init job and set file URL
enable_init_job = true
init_file_url = "https://example.com/sample-file.html"
init_file_name = "index.html"

# Redeploy applications
./deploy.sh applications dev
```

**Note**: The init job will always run but will skip file download/upload if no `fileUrl` is provided.

### s3www Application Configuration
- **Bucket**: `s3www-storage`
- **MinIO Endpoint**: `http://minio:9000`
- **MinIO Credentials**: minioadmin / minioadmin123 <!-- Development credentials - use AWS Secrets Manager in production -->
- **Service Type**: LoadBalancer (direct ALB provisioning)
- **Port**: 8080
- **Image**: `y4m4/s3www:latest`

## 🔍 Comprehensive Troubleshooting Guide

### Common Issues & Solutions

#### 1. MinIO Pods Pending - "Too many pods"
**Problem**: Node pod limit exceeded (t3.small has 11 pods limit)
```bash
# Check node capacity
kubectl describe node | grep -A 5 "Allocated resources"

# Check current pod count
kubectl get pods --all-namespaces -o wide | grep ip-10-0-1-117 | wc -l

# Solution: Upgrade node instance type
# Edit terraform/main.tf: change t3.small to t3.medium
terraform plan
terraform apply
```

#### 2. MinIO Pods Pending - "No persistent volumes available"
**Problem**: Missing EBS CSI Driver
```bash
# Install EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28"

# Verify installation
kubectl get pods -n kube-system | grep ebs-csi
kubectl get storageclass
```

#### 3. Port-Forward Connection Issues
**Problem**: Broken pipe, timeouts, connection refused
```bash
# Use improved port-forward command
kubectl port-forward -n default svc/minio-console 9090:9090 --address 0.0.0.0

# Alternative: Check if service exists
kubectl get svc minio-console

# Kill existing port-forward processes
pkill -f "kubectl port-forward"
```

#### 4. s3www Application CrashLoopBackOff
**Problem**: Environment variable mismatch or configuration errors
```bash
# Check logs
kubectl logs -l app=s3www-app

# Common issues and fixes:
# - S3WWW_BUCKET not set (should be S3WWW_BUCKET, not S3_BUCKET_NAME)
# - S3WWW_ENDPOINT not set (should be http://minio:9000)
# - S3WWW_ADDRESS not set (should be 0.0.0.0:8080)
# - Wrong image: should be y4m4/s3www:latest
```

#### 5. s3www Pods 0/1 Ready - Health Check Failures
**Problem**: Application not listening on correct interface
```bash
# Check if application is listening
kubectl logs -l app=s3www-app | grep "listening"

# Should show: "listening on 0.0.0.0:8080"
# If showing "127.0.0.1:8080", add S3WWW_ADDRESS=0.0.0.0:8080

# Remove health checks if /health endpoint doesn't exist
# Edit helm/s3www-app/templates/deployment.yaml
```

#### 6. ALB Not Provisioning
**Problem**: Service type or ingress configuration issues
```bash
# Check service type
kubectl get svc s3www-app-service

# Should be LoadBalancer, not ClusterIP
# If ClusterIP, update values-custom.yaml:
service:
  type: LoadBalancer
```

#### 7. ALB Controller Permission Issues
**Problem**: IAM permissions for ALB Controller
```bash
# Check ALB Controller logs
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

# Common errors:
# - "UnauthorizedOperation: You are not authorized to perform: ec2:DescribeAvailabilityZones"
# - "no certificate found for host"
# - "error building model: failed to build load balancer config"

# Solution: Use LoadBalancer service type instead of Ingress
```

#### 8. Bucket Configuration Confusion
**Problem**: Mixing AWS S3 bucket with MinIO buckets
```bash
# MinIO provides S3-compatible storage
# No need for separate AWS S3 bucket
# Use MinIO buckets only: s3www-storage

# Remove AWS S3 bucket from Terraform if created
# terraform/main.tf - remove aws_s3_bucket resource
```

### Debug Commands
```bash
# Overall cluster status
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces

# MinIO specific
kubectl get pods -l app.kubernetes.io/name=minio
kubectl logs -l app.kubernetes.io/name=minio
kubectl get pvc -l app.kubernetes.io/name=minio

# s3www application
kubectl get pods -l app=s3www-app
kubectl logs -l app=s3www-app
kubectl get svc s3www-app-service
kubectl describe svc s3www-app-service

# EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi
kubectl get storageclass

# ALB Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

# Node resources
kubectl top nodes
kubectl top pods
```

### MinIO Bucket Management (Command Line)
```bash
# Get MinIO pod name (replace with actual pod name)
MINIO_POD=$(kubectl get pods -l app.kubernetes.io/name=minio -o jsonpath='{.items[0].metadata.name}')

# Configure MinIO client (development credentials - use AWS Secrets Manager in production)
kubectl exec -it $MINIO_POD -- mc alias set myminio http://minio:9000 minioadmin minioadmin123

# List buckets
kubectl exec -it $MINIO_POD -- mc ls myminio

# Create bucket
kubectl exec -it $MINIO_POD -- mc mb myminio/s3www-storage

# Delete bucket (with force to remove non-empty buckets)
kubectl exec -it $MINIO_POD -- mc rb myminio/bucket-name --force

# List objects in bucket
kubectl exec -it $MINIO_POD -- mc ls myminio/s3www-storage

# Upload file to bucket
kubectl exec -it $MINIO_POD -- mc cp /path/to/file myminio/s3www-storage/

# Test MinIO connectivity
kubectl exec -it $MINIO_POD -- mc admin info myminio

# List files that will be served by s3www
kubectl exec -it $MINIO_POD -- mc ls myminio/s3www-storage --recursive
```

### Health Check Commands
```bash
# Test s3www application locally
kubectl port-forward svc/s3www-app-service 8080:80 &
curl http://localhost:8080

# Test ALB access (get your ALB DNS name)
ALB_DNS=$(kubectl get svc s3www-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Your ALB endpoint: http://$ALB_DNS"
curl http://$ALB_DNS

# List files in MinIO bucket
MINIO_POD=$(kubectl get pods -l app.kubernetes.io/name=minio -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $MINIO_POD -- mc ls myminio/s3www-storage

# Check application logs
kubectl logs -l app=s3www-app --tail=50

# Verify MinIO connectivity from s3www
kubectl exec -it $(kubectl get pods -l app=s3www-app -o jsonpath='{.items[0].metadata.name}') -- curl http://minio:9000

# Check service status
kubectl get svc s3www-app-service
```

### Access Your Application
Once deployed, your s3www application will be accessible at:
```
http://ae9b1f154a01942d791c8e3ecce02e89-1376937510.eu-west-1.elb.amazonaws.com/
```

**Note**: The ALB DNS name will be different for your deployment. Get your specific endpoint with:
```bash
kubectl get svc s3www-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 📁 Project Structure
```
up42-challenge-app/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # EKS, VPC, IAM resources
│   ├── variables.tf    # Variable definitions
│   ├── outputs.tf      # Output values
│   └── versions.tf     # Provider versions
├── helm/               # Helm charts
│   └── s3www-app/      # s3www application chart
│       ├── templates/  # Kubernetes manifests
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── ingress.yaml
│       │   └── secret.yaml
│       ├── values.yaml # Default values
│       ├── values-production.yaml # Production template
│       └── values-custom.yaml # Current deployment
└── README.md
```

## 🎯 Success Criteria Checklist
- ✅ EKS cluster running with t3.medium nodes (17 pods capacity)
- ✅ EBS CSI Driver installed and functional
- ✅ MinIO deployed with EBS storage (10Gi)
- ✅ s3www application deployed and accessible
- ✅ LoadBalancer service type configured
- ✅ ALB provisioned and serving content
- ✅ s3www-storage bucket created in MinIO
- ✅ Files uploaded to MinIO served via s3www
- ✅ All pods in Running state (1/1 Ready)
- ✅ No pending pods or resource constraints
- ✅ External access via ALB DNS name
- ✅ Application serving files from MinIO storage
- ✅ ALB endpoint accessible: `http://ae9b1f154a01942d791c8e3ecce02e89-1376937510.eu-west-1.elb.amazonaws.com/`
- ✅ Init job mechanism for automatic file fetching (optional)

## 🔄 Maintenance & Updates
```bash
# Update Helm releases
helm upgrade s3www-app helm/s3www-app -f helm/s3www-app/values-custom.yaml

# Scale applications
kubectl scale deployment s3www-app-deployment --replicas=3

# Monitor resources
kubectl top nodes
kubectl top pods

# Check for updates
helm repo update
helm search repo minio/minio

# Backup MinIO data (if needed)
kubectl exec -it $MINIO_POD -- mc mirror myminio/s3www-storage /backup/
```

## 🚀 Production Deployment

### Production Configuration
For production deployment, use the production values file with SSL/TLS certificates:

```bash
# Deploy with production configuration
helm install s3www-app-prod helm/s3www-app -f helm/s3www-app/values-production.yaml
```

### Production Credentials Management
For production deployments, replace hardcoded credentials with AWS Secrets Manager:

1. **Store credentials in AWS Secrets Manager**:
   ```bash
   aws secretsmanager create-secret \
     --name "minio-credentials" \
     --description "MinIO credentials for s3www application" \
     --secret-string '{"access-key":"your-production-access-key","secret-key":"your-production-secret-key"}'
   ```

2. **Update Helm values to use secrets**:
   ```yaml
   # In values-production.yaml
   config:
     minioAccessKey: ""  # Will be fetched from AWS Secrets Manager
     minioSecretKey: ""  # Will be fetched from AWS Secrets Manager
   ```

3. **Use External Secrets Operator** (recommended):
   ```yaml
   # Create ExternalSecret to fetch from AWS Secrets Manager
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: minio-credentials
   spec:
     secretStoreRef:
       name: aws-secrets-manager
       kind: SecretStore
     target:
       name: s3www-app-minio-secret
     data:
     - secretKey: access-key
       remoteRef:
         key: minio-credentials
         property: access-key
     - secretKey: secret-key
       remoteRef:
         key: minio-credentials
         property: secret-key
   ```

### SSL/TLS Configuration
The production values file includes ACM certificate configuration:

```yaml
# helm/s3www-app/values-production.yaml
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:region:account:certificate/certificate-id"
  hosts:
    - host: s3www.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

### ACM Certificate Setup
1. **Request Certificate in ACM**:
   ```bash
   aws acm request-certificate \
     --domain-name s3www.yourdomain.com \
     --validation-method DNS \
     --region eu-west-1
   ```

2. **Update values-production.yaml**:
   - Replace `certificate-arn` with your ACM certificate ARN
   - Update `host` with your domain name

3. **Deploy with Production Values**:
   ```bash
   helm upgrade s3www-app helm/s3www-app -f helm/s3www-app/values-production.yaml
   ```

### Production Recommendations

#### Scaling
- **Multi-node cluster**: For high availability
- **t3.medium+ instances**: Better performance
- **Auto-scaling**: HPA for s3www application
- **Multi-AZ deployment**: Across availability zones

#### Security
- **IAM roles**: Least privilege access
- **Network policies**: Restrict pod-to-pod communication
- **Secrets management**: AWS Secrets Manager for credentials (replace hardcoded values)
- **RBAC**: Kubernetes role-based access control
- **SSL/TLS**: ACM certificates for HTTPS
- **WAF**: Web Application Firewall protection

#### Monitoring
- **Prometheus/Grafana**: Application metrics
- **CloudWatch**: AWS resource monitoring
- **Log aggregation**: Fluentd/Fluent Bit
- **Health checks**: Application readiness probes
- **Alerting**: CloudWatch alarms and notifications

## 📚 Key Learnings

### Infrastructure
1. **Node sizing**: t3.small (11 pods) vs t3.medium (17 pods) makes a difference
2. **EBS CSI Driver**: Essential for persistent storage
3. **ALB Controller**: Complex IAM permissions, LoadBalancer service type is simpler

### Application
1. **Environment variables**: s3www expects S3WWW_* prefix
2. **Health checks**: Remove if /health endpoint doesn't exist
3. **Service types**: LoadBalancer vs ClusterIP + Ingress trade-offs

### Storage
1. **MinIO vs AWS S3**: MinIO provides S3-compatible storage locally
2. **Bucket management**: Use meaningful bucket names
3. **EBS volumes**: Automatic provisioning via CSI driver

## 🤝 Support

- Check the troubleshooting guide above
- Review logs: t`
- Verify configuration: `helm get values s3www-app`
- Test connectivity: `kubectl port-forward` and curl commands
- Check pod status: `kubectl get pods -l app=s3www-app`
- Verify MinIO connectivity: `kubectl exec -it $MINIO_POD -- mc admin info myminio`

---

**Status**: ✅ **COMPLETE** - All components deployed and functional
**Last Updated**: July 2024
**Version**: 1.0.0
