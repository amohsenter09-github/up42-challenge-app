#!/bin/bash

# UP42 Challenge - Complete Terraform Deployment Script
# Manages full lifecycle of infrastructure and applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are satisfied"
}

# Function to bootstrap S3 backend
bootstrap_backend() {
    print_status "Bootstrapping S3 backend..."
    
    if [ ! -f "backend.tf" ]; then
        if [ -f "bootstrap.sh" ]; then
            chmod +x bootstrap.sh
            ./bootstrap.sh
        else
            print_error "bootstrap.sh not found. Please create it first."
            exit 1
        fi
    else
        print_warning "Backend already configured"
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    
    print_status "Deploying infrastructure for environment: $environment"
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    print_status "Planning infrastructure deployment..."
    terraform plan -var-file="environments/$environment.tfvars" -out=tfplan
    
    # Apply deployment
    print_status "Applying infrastructure deployment..."
    terraform apply tfplan
    
    # Configure kubectl
    print_status "Configuring kubectl..."
    aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)
    
    print_success "Infrastructure deployed successfully"
}

# Function to install EBS CSI Driver
install_ebs_csi_driver() {
    print_status "Installing EBS CSI Driver..."
    
    kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28"
    
    # Wait for EBS CSI Driver to be ready
    print_status "Waiting for EBS CSI Driver to be ready..."
    kubectl wait --for=condition=ready pod -l app=ebs-csi-node -n kube-system --timeout=300s
    
    print_success "EBS CSI Driver installed successfully"
}

# Function to deploy applications
deploy_applications() {
    local environment=$1
    
    print_status "Deploying applications for environment: $environment"
    
    # Apply the Kubernetes applications module
    terraform apply -var-file="environments/$environment.tfvars" -target=module.kubernetes_apps
    
    print_success "Applications deployed successfully"
}

# Function to verify deployment
verify_deployment() {
    local environment=$1
    
    print_status "Verifying deployment for environment: $environment"
    
    # Check nodes
    print_status "Checking cluster nodes..."
    kubectl get nodes
    
    # Check pods
    print_status "Checking application pods..."
    kubectl get pods --all-namespaces
    
    # Check services
    print_status "Checking services..."
    kubectl get svc --all-namespaces
    
    # Check if ALB is provisioned
    if [ "$environment" = "production" ]; then
        print_status "Checking ALB status..."
        kubectl get svc s3www-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || print_warning "ALB not yet provisioned"
    fi
    
    print_success "Deployment verification completed"
}

# Function to scale down cluster
scale_down() {
    print_status "Scaling down cluster to save costs..."
    
    # Update node group to 0 instances
    sed -i '' 's/desired_size = [0-9]/desired_size = 0/' main.tf
    sed -i '' 's/min_size     = [0-9]/min_size     = 0/' main.tf
    
    terraform apply -auto-approve
    
    print_success "Cluster scaled down successfully"
}

# Function to scale up cluster
scale_up() {
    print_status "Scaling up cluster..."
    
    # Update node group back to 1 instance
    sed -i '' 's/desired_size = 0/desired_size = 1/' main.tf
    sed -i '' 's/min_size     = 0/min_size     = 1/' main.tf
    
    terraform apply -auto-approve
    
    print_success "Cluster scaled up successfully"
}

# Function to destroy everything
destroy_all() {
    print_warning "This will destroy ALL resources. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Destroying all resources..."
        terraform destroy -auto-approve
        print_success "All resources destroyed"
    else
        print_status "Destroy cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "UP42 Challenge - Terraform Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [ENVIRONMENT]"
    echo ""
    echo "Commands:"
    echo "  deploy [dev|production]  - Deploy infrastructure and applications"
    echo "  infrastructure [dev|production] - Deploy only infrastructure"
    echo "  applications [dev|production]   - Deploy only applications"
    echo "  verify [dev|production]         - Verify deployment"
    echo "  scale-down                      - Scale down cluster to save costs"
    echo "  scale-up                        - Scale up cluster"
    echo "  destroy                         - Destroy all resources"
    echo "  help                            - Show this help message"
    echo ""
    echo "Environments:"
    echo "  dev         - Development environment (default)"
    echo "  production  - Production environment"
    echo ""
    echo "Examples:"
    echo "  $0 deploy dev"
    echo "  $0 deploy production"
    echo "  $0 scale-down"
    echo "  $0 destroy"
}

# Main script logic
main() {
    local command=$1
    local environment=${2:-dev}
    
    case $command in
        "deploy")
            check_prerequisites
            bootstrap_backend
            deploy_infrastructure "$environment"
            install_ebs_csi_driver
            deploy_applications "$environment"
            verify_deployment "$environment"
            print_success "Complete deployment finished successfully!"
            ;;
        "infrastructure")
            check_prerequisites
            bootstrap_backend
            deploy_infrastructure "$environment"
            install_ebs_csi_driver
            ;;
        "applications")
            deploy_applications "$environment"
            ;;
        "verify")
            verify_deployment "$environment"
            ;;
        "scale-down")
            scale_down
            ;;
        "scale-up")
            scale_up
            ;;
        "destroy")
            destroy_all
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 