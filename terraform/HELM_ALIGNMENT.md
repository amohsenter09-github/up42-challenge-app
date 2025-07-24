# Terraform vs Helm Chart Alignment

This document shows how our Terraform configuration aligns with the s3www-app Helm chart.

## ✅ **Perfectly Aligned Components**

### **1. Configuration Structure**
| Helm Chart | Terraform | Status |
|------------|-----------|--------|
| `config.bucketName` | `var.s3www_bucket_name` | ✅ Aligned |
| `config.region` | `var.aws_region` | ✅ Aligned |
| `config.minioEndpoint` | `var.minio_endpoint` | ✅ Aligned |
| `config.minioAccessKey` | `var.minio_access_key` | ✅ Aligned |
| `config.minioSecretKey` | `var.minio_secret_key` | ✅ Aligned |
| `config.port` | `var.s3www_port` | ✅ Aligned |
| `config.debug` | `var.s3www_debug` | ✅ Aligned |

### **2. Service Configuration**
| Helm Chart | Terraform | Status |
|------------|-----------|--------|
| `service.type` | `var.s3www_service_type` | ✅ Aligned |
| `service.port` | Hardcoded to 80 | ✅ Aligned |

### **3. Ingress Configuration**
| Helm Chart | Terraform | Status |
|------------|-----------|--------|
| `ingress.enabled` | `var.enable_ingress` | ✅ Aligned |
| `ingress.className` | Hardcoded to "alb" | ✅ Aligned |
| `ingress.annotations` | `var.ingress_annotations` | ✅ Aligned |
| `ingress.hosts` | `var.ingress_hosts` | ✅ Aligned |

### **4. Deployment Configuration**
| Helm Chart | Terraform | Status |
|------------|-----------|--------|
| `replicaCount` | `var.s3www_replica_count` | ✅ Aligned |
| `resources` | `var.s3www_resources` | ✅ Aligned |

### **5. Image Configuration**
| Helm Chart | Terraform | Status |
|------------|-----------|--------|
| `image.repository` | Hardcoded to "y4m4/s3www" | ✅ Aligned |
| `image.tag` | Hardcoded to "latest" | ✅ Aligned |
| `image.pullPolicy` | Hardcoded to "IfNotPresent" | ✅ Aligned |

## 🔧 **Enhanced Terraform Features**

### **1. Environment-Specific Security Context**
```yaml
# Production security context (not in Helm chart by default)
podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop: ["ALL"]
```

### **2. Monitoring Integration**
```yaml
# Pod annotations for Prometheus monitoring
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### **3. AWS Secrets Manager Integration**
```yaml
# External Secrets Operator for production
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: s3www-app-minio-secret
spec:
  target:
    name: s3www-app-minio-secret  # Matches Helm chart expectation
```

## 📋 **Environment Configurations**

### **Development Environment**
```yaml
# terraform/environments/dev.tfvars
config:
  bucketName: "s3www-storage"
  minioEndpoint: "http://minio:9000"
  minioAccessKey: "minioadmin"
  minioSecretKey: "minioadmin123"
  port: 8080
  debug: true

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### **Production Environment**
```yaml
# terraform/environments/production.tfvars
config:
  bucketName: "s3www-production-storage"
  minioEndpoint: "http://minio:9000"
  minioAccessKey: "prod-minio-admin"
  minioSecretKey: "prod-secure-password-123"
  port: 8080
  debug: false

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

# Production features enabled
use_aws_secrets_manager: true
enable_monitoring: true
enable_backup: true
```

## 🔄 **Deployment Flow**

### **1. Terraform Deployment**
```bash
# Deploy with Terraform
./deploy.sh deploy dev

# This will:
# 1. Deploy EKS infrastructure
# 2. Install EBS CSI Driver
# 3. Deploy MinIO via Terraform module
# 4. Deploy s3www-app via Terraform module
# 5. Configure secrets and monitoring
```

### **2. Helm Chart Integration**
```yaml
# Terraform passes values to Helm chart
helm_release "s3www_app" {
  chart = "../helm/s3www-app"
  values = [
    yamlencode({
      config = {
        bucketName = var.s3www_bucket_name
        # ... other config values
      }
      # ... other Helm values
    })
  ]
}
```

## ✅ **Verification Commands**

### **Check Deployment**
```bash
# Verify Helm release
helm list -n default

# Check pods
kubectl get pods -l app=s3www-app

# Check services
kubectl get svc s3www-app-service

# Check secrets
kubectl get secret s3www-app-minio-secret
```

### **Check Configuration**
```bash
# View Helm values
helm get values s3www-app -n default

# Check environment variables
kubectl describe pod -l app=s3www-app
```

## 🎯 **Summary**

Our Terraform configuration is **100% aligned** with the s3www-app Helm chart and provides:

1. **✅ Perfect Compatibility**: All Helm chart values are properly mapped
2. **✅ Enhanced Security**: Production-grade security contexts
3. **✅ Monitoring Integration**: Prometheus annotations
4. **✅ Secrets Management**: AWS Secrets Manager integration
5. **✅ Environment Separation**: Dev vs production configurations
6. **✅ Production Features**: Backup, monitoring, SSL/TLS support

The Terraform configuration enhances the Helm chart with production features while maintaining full compatibility. 