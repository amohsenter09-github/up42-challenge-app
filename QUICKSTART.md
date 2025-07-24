# 🚀 Quick Start Guide

This guide will get you up and running with the s3www application and MinIO on AWS EKS in under 10 minutes.

## Prerequisites

- **AWS CLI** configured with appropriate permissions
- **kubectl** installed and configured
- **Terraform** (v1.0+) installed
- **Helm** (v3.0+) installed
- **Git** for cloning the repository

## 🎯 Quick Deployment

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd up42-challenge-app

# Navigate to terraform directory
cd terraform
```

### 2. Deploy Everything (One Command)

```bash
# Deploy complete infrastructure and applications
./deploy.sh all dev
```

This single command will:
- ✅ Create VPC, EKS cluster, and all infrastructure
- ✅ Install EBS CSI Driver
- ✅ Deploy MinIO with persistent storage
- ✅ Deploy s3www application
- ✅ Configure LoadBalancer for external access

### 3. Access Your Application

```bash
# Get the ALB endpoint
kubectl get svc s3www-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or use the provided command
./deploy.sh status dev
```

### 4. Upload Files to MinIO

```bash
# Access MinIO console
kubectl port-forward -n default svc/minio-console 9090:9090 --address 0.0.0.0

# Open browser: http://localhost:9090
# Login: minioadmin / minioadmin123
# Create bucket: s3www-storage
# Upload your files
```

## 🔧 Development Workflow

### Local Development

```bash
# For local testing without AWS
docker-compose up -d
```

### Environment Management

```bash
# Switch to production
./deploy.sh all production

# Scale down for cost savings
./deploy.sh scale-down dev

# Scale back up
./deploy.sh scale-up dev
```

### Application Updates

```bash
# Update only applications (keep infrastructure)
./deploy.sh applications dev

# Update with new configuration
./deploy.sh applications dev --var-file=environments/dev.tfvars
```

## 📊 Monitoring & Debugging

### Check Application Status

```bash
# View all resources
kubectl get all

# Check pod logs
kubectl logs -l app=s3www-app

# Check MinIO logs
kubectl logs -l app=minio
```

### Access Services

```bash
# s3www application
kubectl port-forward svc/s3www-app-service 8080:8080

# MinIO console
kubectl port-forward svc/minio-console 9090:9090

# MinIO API
kubectl port-forward svc/minio 9000:9000
```

## 🧹 Cleanup

```bash
# Destroy everything
./deploy.sh destroy dev

# Or scale down to zero (keeps infrastructure)
./deploy.sh scale-down dev
```

## 🚨 Troubleshooting

### Common Issues

1. **Pods Pending**
   ```bash
   kubectl describe pod <pod-name>
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Service Not Accessible**
   ```bash
   kubectl get svc
   kubectl describe svc <service-name>
   ```

3. **Storage Issues**
   ```bash
   kubectl get pvc
   kubectl describe pvc <pvc-name>
   ```

### Quick Fixes

```bash
# Restart deployments
kubectl rollout restart deployment/s3www-app-deployment
kubectl rollout restart statefulset/minio

# Check node resources
kubectl top nodes
kubectl top pods

# Verify EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi
```

## 📚 Next Steps

- 📖 Read the [Architecture Documentation](ARCHITECTURE.md)
- 🔧 Explore [Terraform Configuration](terraform/DEPLOYMENT.md)
- 📦 Review [Helm Chart Details](helm/s3www-app/CHART.md)
- 🎯 Check [Design Decisions](DESIGN.md)

## 🆘 Need Help?

- 📋 Check the [Main README](README.md) for detailed documentation
- 🐛 Review [Troubleshooting Guide](README.md#troubleshooting-guide)
- 🔍 Examine [Architecture Overview](ARCHITECTURE.md)
- 💡 Look at [Design Decisions](DESIGN.md) for implementation rationale

---

**Happy Deploying! 🚀** 