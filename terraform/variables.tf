# Minimal variables for UP42 Challenge AWS Infrastructure

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"  # Ireland region
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "up42-challenge"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
} 