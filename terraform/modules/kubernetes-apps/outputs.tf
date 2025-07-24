# Outputs for Kubernetes Applications Module

output "minio_service_name" {
  description = "Name of the MinIO service"
  value       = var.enable_minio ? helm_release.minio[0].name : null
}

output "minio_namespace" {
  description = "Namespace where MinIO is deployed"
  value       = var.enable_minio ? helm_release.minio[0].namespace : null
}

output "s3www_service_name" {
  description = "Name of the s3www service"
  value       = var.enable_s3www ? helm_release.s3www_app[0].name : null
}

output "s3www_namespace" {
  description = "Namespace where s3www is deployed"
  value       = var.enable_s3www ? helm_release.s3www_app[0].namespace : null
}

output "minio_credentials_secret_arn" {
  description = "ARN of the MinIO credentials secret in AWS Secrets Manager"
  value       = var.use_aws_secrets_manager ? aws_secretsmanager_secret.minio_credentials[0].arn : null
}

output "backup_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = var.enable_backup ? aws_s3_bucket.backup[0].bucket : null
}

output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = var.enable_monitoring ? "monitoring" : null
}

output "velero_namespace" {
  description = "Namespace where Velero is deployed"
  value       = var.enable_backup ? "velero" : null
}

output "application_endpoints" {
  description = "Application endpoints and access information"
  value = {
    minio_console = var.enable_minio ? "kubectl port-forward -n ${var.namespace} svc/minio-console 9090:9090" : null
    s3www_service = var.enable_s3www ? "kubectl get svc -n ${var.namespace} s3www-app-service" : null
    grafana       = var.enable_monitoring ? "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" : null
  }
} 