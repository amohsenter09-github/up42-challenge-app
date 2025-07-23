# Minimal Terraform configuration for UP42 Challenge AWS Infrastructure
# Simplified for test/demo purposes - Deployed in Ireland (eu-west-1)

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module - Minimal configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for EKS
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# EKS Cluster - Minimal configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"  # Specific version known to work

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Single node group with minimal resources
  eks_managed_node_groups = {
    general = {
      name = "general-node-group"

      instance_types = ["t3.medium"]  # Upgraded for better pod capacity
      capacity_type  = "ON_DEMAND"

      min_size     = 0  # Scaled down to save costs
      max_size     = 1  # Keep at 1 to satisfy EKS requirements
      desired_size = 0  # Scale down to 0 instances

      disk_size = 20

      labels = {
        Environment = "production"
        NodeGroup   = "general"
      }
    }
  }

  # Remove problematic security group rules for now
  # The module will create default security groups
}

# MinIO provides S3-compatible storage for the application
# No AWS S3 bucket needed - MinIO handles all storage requirements 