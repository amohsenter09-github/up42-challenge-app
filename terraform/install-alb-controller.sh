#!/bin/bash

# ALB Controller Installation Script
# This script installs the AWS Load Balancer Controller after the EKS cluster is ready

set -e

echo "🚀 Installing AWS Load Balancer Controller"
echo "=========================================="

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ kubectl is not configured. Please run:"
    echo "   aws eks update-kubeconfig --name up42-challenge --region eu-west-1"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install helm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Add the AWS EKS Helm repository
echo "📦 Adding AWS EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM OIDC provider for the cluster
echo "🔧 Creating IAM OIDC provider..."
eksctl utils associate-iam-oidc-provider --region eu-west-1 --cluster up42-challenge --approve

# Create IAM policy for ALB Controller
echo "🔧 Creating IAM policy..."
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://alb-controller-policy.json \
    --region eu-west-1 || echo "Policy already exists"

# Create IAM role and service account
echo "🔧 Creating IAM role and service account..."
eksctl create iamserviceaccount \
    --region eu-west-1 \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --cluster up42-challenge \
    --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
    --approve \
    --override-existing-serviceaccounts

# Install the AWS Load Balancer Controller
echo "🚀 Installing AWS Load Balancer Controller..."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=up42-challenge \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

echo ""
echo "✅ AWS Load Balancer Controller installed successfully!"
echo ""
echo "🔍 Verifying installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller

echo ""
echo "📋 ALB Controller is now ready to handle ingress resources!" 