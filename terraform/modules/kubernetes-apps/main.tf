# Kubernetes Applications Module
# Manages the deployment of MinIO and s3www applications

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# MinIO Deployment
resource "helm_release" "minio" {
  count      = var.enable_minio ? 1 : 0
  name       = "minio"
  repository = "https://charts.bitnami.com/minio"
  chart      = "minio"
  namespace  = var.namespace
  create_namespace = true

  set {
    name  = "auth.rootUser"
    value = var.minio_root_user
  }

  set {
    name  = "auth.rootPassword"
    value = var.minio_root_password
  }

  set {
    name  = "persistence.size"
    value = var.minio_persistence_size
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  # Production: Use AWS Secrets Manager
  dynamic "set" {
    for_each = var.use_aws_secrets_manager ? [1] : []
    content {
      name  = "auth.existingSecret"
      value = var.minio_secret_name
    }
  }

  depends_on = [kubernetes_namespace.apps]
}

# s3www Application Deployment
resource "helm_release" "s3www_app" {
  count      = var.enable_s3www ? 1 : 0
  name       = "s3www-app"
  chart      = var.s3www_chart_path
  namespace  = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      # Application configuration - matches Helm chart structure
      config = {
        bucketName     = var.s3www_bucket_name
        region         = var.aws_region
        minioEndpoint  = var.minio_endpoint
        minioAccessKey = var.use_aws_secrets_manager ? "" : var.minio_access_key
        minioSecretKey = var.use_aws_secrets_manager ? "" : var.minio_secret_key
        port           = var.s3www_port
        debug          = var.s3www_debug
      }
      
      # Service configuration
      service = {
        type = var.s3www_service_type
        port = 80
      }
      
      # Ingress configuration
      ingress = {
        enabled = var.enable_ingress
        className = "alb"
        annotations = var.ingress_annotations
        hosts = var.ingress_hosts
      }
      
      # Deployment configuration
      replicaCount = var.s3www_replica_count
      resources = var.s3www_resources
      
      # Image configuration
      image = {
        repository = "y4m4/s3www"
        tag = "latest"
        pullPolicy = "IfNotPresent"
      }
      
      # Service account configuration
      serviceAccount = {
        create = true
        annotations = {}
      }
      
      # Security context for production
      podSecurityContext = var.environment == "production" ? {
        fsGroup = 1000
        runAsNonRoot = true
        runAsUser = 1000
      } : null
      
      securityContext = var.environment == "production" ? {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem = true
        runAsNonRoot = true
        capabilities = {
          drop = ["ALL"]
        }
      } : null
      
      # Pod annotations for monitoring
      podAnnotations = var.enable_monitoring ? {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port" = "8080"
        "prometheus.io/path" = "/metrics"
      } : {}
      
      # Init job configuration (always enabled, controlled by fileUrl)
      init = {
        enabled = true  # Always enabled, controlled by fileUrl
        image = {
          repository = "alpine"
          tag = "latest"
          pullPolicy = "IfNotPresent"
        }
        fileUrl = var.enable_init_job ? var.init_file_url : ""
        fileName = var.init_file_name
      }
    })
  ]

  depends_on = [helm_release.minio]
}

# Kubernetes Namespace
resource "kubernetes_namespace" "apps" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# AWS Secrets Manager Integration (Production)
resource "aws_secretsmanager_secret" "minio_credentials" {
  count = var.use_aws_secrets_manager ? 1 : 0
  name  = "${var.environment}-minio-credentials"
  description = "MinIO credentials for ${var.environment} environment"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "minio_credentials" {
  count     = var.use_aws_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.minio_credentials[0].id

  secret_string = jsonencode({
    access-key = var.minio_access_key
    secret-key = var.minio_secret_key
  })
}

# External Secrets Operator (if enabled)
resource "kubernetes_manifest" "external_secret" {
  count = var.use_aws_secrets_manager && var.enable_external_secrets ? 1 : 0
  
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "s3www-app-minio-secret"
      namespace = var.namespace
    }
    spec = {
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "SecretStore"
      }
      target = {
        name = "s3www-app-minio-secret"
        type = "Opaque"
      }
      data = [
        {
          secretKey = "access-key"
          remoteRef = {
            key      = aws_secretsmanager_secret.minio_credentials[0].name
            property = "access-key"
          }
        },
        {
          secretKey = "secret-key"
          remoteRef = {
            key      = aws_secretsmanager_secret.minio_credentials[0].name
            property = "secret-key"
          }
        }
      ]
    }
  }

  depends_on = [aws_secretsmanager_secret_version.minio_credentials]
}

# Monitoring and Logging (Production)
resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.enabled"
    value = "true"
  }
}

# Backup and Disaster Recovery
resource "aws_s3_bucket" "backup" {
  count  = var.enable_backup ? 1 : 0
  bucket = "${var.environment}-${var.cluster_name}-backup-${random_string.suffix[0].result}"

  tags = {
    Environment = var.environment
    Purpose     = "backup"
    ManagedBy   = "terraform"
  }
}

resource "random_string" "suffix" {
  count   = var.enable_backup ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Velero for Kubernetes backup
resource "helm_release" "velero" {
  count      = var.enable_backup ? 1 : 0
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = "velero"
  create_namespace = true

  set {
    name  = "configuration.provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation.name"
    value = "default"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = aws_s3_bucket.backup[0].bucket
  }

  set {
    name  = "configuration.volumeSnapshotLocation.name"
    value = "default"
  }

  set {
    name  = "configuration.volumeSnapshotLocation.config.region"
    value = var.aws_region
  }
} 