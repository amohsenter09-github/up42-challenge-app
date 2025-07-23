#!/bin/bash

# UP42 Challenge Infrastructure Deployment Script
# This script deploys the infrastructure in two phases:
# Phase 1: EKS cluster and basic infrastructure
# Phase 2: ALB Controller and other post-EKS resources

set -e

echo "🚀 Starting UP42 Challenge Infrastructure Deployment"
echo "=================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install helm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Phase 1: Deploy EKS Infrastructure
echo ""
echo "📦 Phase 1: Deploying EKS Infrastructure"
echo "========================================"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply the infrastructure
echo "🚀 Applying infrastructure..."
terraform apply tfplan

echo ""
echo "✅ Phase 1 completed successfully!"
echo ""

# Wait for EKS cluster to be ready
echo "⏳ Waiting for EKS cluster to be ready..."
aws eks wait cluster-active --name up42-challenge --region eu-west-1

# Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --name up42-challenge --region eu-west-1

# Verify cluster is accessible
echo "🔍 Verifying cluster connectivity..."
kubectl get nodes

echo ""
echo "✅ EKS cluster is ready!"
echo ""

# Phase 2: Deploy ALB Controller
echo "📦 Phase 2: Deploying ALB Controller"
echo "===================================="

# Ask if user wants to proceed with ALB Controller
read -p "🤔 Do you want to deploy the ALB Controller now? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "ℹ️  ALB Controller deployment skipped. You can deploy it later with:"
    echo "   ./install-alb-controller.sh"
    exit 0
fi

# Deploy ALB Controller
echo "🚀 Deploying ALB Controller..."
chmod +x install-alb-controller.sh
./install-alb-controller.sh

echo ""
echo "✅ ALB Controller deployed successfully!"
echo ""

echo ""
echo "🎉 Infrastructure deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy MinIO: helm install minio minio/minio --set auth.rootUser=minioadmin --set auth.rootPassword=minioadmin123"
echo "2. Deploy s3www app: helm install s3www-app ./helm/s3www-app -f ./helm/s3www-app/values-custom.yaml"
echo "3. Update values-custom.yaml with your actual bucket name and MinIO credentials"
echo ""
echo "🔗 Useful commands:"
echo "- Check cluster status: kubectl get nodes"
echo "- Check ALB Controller: kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"
echo "- Get cluster info: aws eks describe-cluster --name up42-challenge --region eu-west-1" 