# Variables for Kubernetes Applications Module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# MinIO Configuration
variable "enable_minio" {
  description = "Enable MinIO deployment"
  type        = bool
  default     = true
}

variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  default     = "minioadmin123"
  sensitive   = true
}

variable "minio_persistence_size" {
  description = "MinIO persistence size"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "ebs-sc"
}

# s3www Configuration
variable "enable_s3www" {
  description = "Enable s3www application deployment"
  type        = bool
  default     = true
}

variable "s3www_chart_path" {
  description = "Path to s3www Helm chart"
  type        = string
  default     = "../helm/s3www-app"
}

variable "s3www_bucket_name" {
  description = "S3 bucket name for s3www application"
  type        = string
  default     = "s3www-storage"
}

variable "minio_endpoint" {
  description = "MinIO service endpoint"
  type        = string
  default     = "http://minio:9000"
}

variable "minio_access_key" {
  description = "MinIO access key"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_secret_key" {
  description = "MinIO secret key"
  type        = string
  default     = "minioadmin123"
  sensitive   = true
}

variable "s3www_port" {
  description = "s3www application port"
  type        = number
  default     = 8080
}

variable "s3www_debug" {
  description = "Enable debug mode for s3www"
  type        = bool
  default     = false
}

variable "s3www_service_type" {
  description = "s3www service type"
  type        = string
  default     = "LoadBalancer"
}

variable "s3www_replica_count" {
  description = "Number of s3www replicas"
  type        = number
  default     = 2
}

variable "s3www_resources" {
  description = "Resource limits for s3www pods"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable ingress for s3www application"
  type        = bool
  default     = false
}

variable "ingress_annotations" {
  description = "Annotations for ingress"
  type        = map(string)
  default = {
    "alb.ingress.kubernetes.io/scheme"        = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"   = "ip"
    "alb.ingress.kubernetes.io/listen-ports"  = "[{\"HTTP\": 80}]"
  }
}

variable "ingress_hosts" {
  description = "Hosts for ingress"
  type = list(object({
    host = string
    paths = list(object({
      path     = string
      pathType = string
    }))
  }))
  default = [
    {
      host = "s3www.local"
      paths = [
        {
          path     = "/"
          pathType = "Prefix"
        }
      ]
    }
  ]
}

# Production Features
variable "use_aws_secrets_manager" {
  description = "Use AWS Secrets Manager for credentials"
  type        = bool
  default     = false
}

variable "minio_secret_name" {
  description = "Name of the Kubernetes secret for MinIO credentials"
  type        = string
  default     = "minio-credentials"
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = false
}

# Monitoring and Logging
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus/Grafana)"
  type        = bool
  default     = false
}

# Backup and Disaster Recovery
variable "enable_backup" {
  description = "Enable backup and disaster recovery"
  type        = bool
  default     = false
}

# Init Job Configuration
variable "enable_init_job" {
  description = "Enable initialization job to fetch and upload files"
  type        = bool
  default     = false
}

variable "init_file_url" {
  description = "URL to fetch the file to serve"
  type        = string
  default     = ""
}

variable "init_file_name" {
  description = "Name of the file to save"
  type        = string
  default     = "index.html"
} 