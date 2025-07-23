# S3WWW Application Helm Chart

This Helm chart deploys the s3www application on Kubernetes with MinIO integration.

## Prerequisites

- Kubernetes cluster with ALB Ingress Controller installed
- MinIO instance running (can be deployed separately)
- S3 bucket for application data

## Installation

1. **Update the values.yaml file** with your specific configuration:

```yaml
config:
  bucketName: "your-s3-bucket-name"
  region: "eu-west-1"
  minioEndpoint: "minio-service:9000"
  minioAccessKey: "your-minio-access-key"
  minioSecretKey: "your-minio-secret-key"
```

2. **Deploy the application**:

```bash
helm install s3www-app ./helm/s3www-app
```

3. **For production deployment**:

```bash
helm install s3www-app ./helm/s3www-app \
  --set config.bucketName=your-bucket \
  --set config.minioAccessKey=your-access-key \
  --set config.minioSecretKey=your-secret-key \
  --set ingress.hosts[0].host=your-domain.com
```

## Configuration

### Application Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.bucketName` | S3 bucket name for application data | `""` |
| `config.region` | AWS region | `"eu-west-1"` |
| `config.minioEndpoint` | MinIO service endpoint | `"minio-service:9000"` |
| `config.minioAccessKey` | MinIO access key | `""` |
| `config.minioSecretKey` | MinIO secret key | `""` |
| `config.port` | Application port | `8080` |
| `config.debug` | Enable debug mode | `false` |

### Deployment Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Container image repository | `"s3www"` |
| `image.tag` | Container image tag | `"latest"` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `"s3www.local"` |
| `ingress.annotations` | Ingress annotations | ALB-specific |

## Components

- **Deployment**: Runs the s3www application pods
- **Service**: Exposes the application internally
- **Ingress**: Provides external access via ALB
- **ServiceAccount**: Kubernetes service account
- **Secret**: Stores MinIO credentials
- **HPA**: Horizontal Pod Autoscaler for scaling

## Upgrading

```bash
helm upgrade s3www-app ./helm/s3www-app
```

## Uninstalling

```bash
helm uninstall s3www-app
```

## Troubleshooting

1. **Check pod status**:
   ```bash
   kubectl get pods -l app=s3www-app
   ```

2. **Check logs**:
   ```bash
   kubectl logs -l app=s3www-app
   ```

3. **Check ingress status**:
   ```bash
   kubectl get ingress s3www-app-ingress
   ```

4. **Verify MinIO connectivity**:
   ```bash
   kubectl exec -it deployment/s3www-app-deployment -- curl minio-service:9000
   ``` 