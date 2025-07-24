# 🏗️ Architecture Overview

## System Architecture

This project implements a production-ready deployment of the s3www application with MinIO dependency on AWS EKS using Helm and Terraform.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   VPC & Network │    │   EKS Cluster   │    │   Storage   │  │
│  │                 │    │                 │    │             │  │
│  │ • Public Subnets│    │ • Control Plane │    │ • EBS Volumes│  │
│  │ • Private Subnets│   │ • Worker Nodes  │    │ • S3 Buckets│  │
│  │ • NAT Gateway   │    │ • Auto Scaling  │    │             │  │
│  │ • Internet Gateway│  │ • Load Balancers│    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Layer                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   MinIO Storage │    │  s3www App      │    │   Services  │  │
│  │                 │    │                 │    │             │  │
│  │ • S3-Compatible │    │ • Go Web Server │    │ • LoadBalancer│ │
│  │ • Object Storage│    │ • File Serving  │    │ • Ingress   │  │
│  │ • Persistent    │    │ • S3 Integration│    │ • Monitoring│  │
│  │ • Multi-AZ      │    │ • Metrics       │    │ • Backup    │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Infrastructure Layer (Terraform)

#### VPC & Networking
- **Multi-AZ VPC**: High availability across availability zones
- **Public Subnets**: For load balancers and bastion hosts
- **Private Subnets**: For application workloads
- **NAT Gateway**: Outbound internet access for private subnets
- **Internet Gateway**: Inbound internet access

#### EKS Cluster
- **Managed Control Plane**: AWS-managed Kubernetes control plane
- **Worker Node Groups**: Auto-scaling EC2 instances
- **IAM Integration**: Service accounts with AWS permissions
- **EBS CSI Driver**: Dynamic volume provisioning

#### Security
- **Security Groups**: Network-level security
- **IAM Roles**: Service account permissions
- **Secrets Management**: AWS Secrets Manager integration
- **Pod Security**: Security contexts and policies

### 2. Application Layer (Helm)

#### MinIO Component
- **StatefulSet**: Persistent storage with EBS
- **Service**: Internal cluster communication
- **Console**: Web-based management interface
- **Credentials**: Kubernetes secrets or AWS Secrets Manager

#### s3www Component
- **Deployment**: Stateless application pods
- **Service**: LoadBalancer for external access
- **Ingress**: ALB integration for HTTP routing
- **HPA**: Horizontal pod autoscaling
- **Init Job**: Automatic file fetching and upload

#### Supporting Components
- **Service Accounts**: Pod identity and permissions
- **Secrets**: Credential management
- **ConfigMaps**: Configuration management
- **Monitoring**: Prometheus annotations and metrics

## Data Flow

### 1. External Access Flow
```
Internet → ALB → Ingress → Service → Pod → s3www App → MinIO
```

### 2. File Upload Flow
```
Init Job → Download File → MinIO Client → MinIO Storage
```

### 3. File Serving Flow
```
User Request → s3www App → MinIO API → File Response
```

## Security Architecture

### Network Security
- **Private Subnets**: Application pods in private subnets
- **Security Groups**: Restrictive network policies
- **NAT Gateway**: Controlled outbound access
- **Load Balancer**: Public access point only

### Application Security
- **Pod Security Contexts**: Non-root execution
- **Service Accounts**: Least privilege access
- **Secrets Management**: Encrypted credential storage
- **Network Policies**: Pod-to-pod communication control

### Infrastructure Security
- **IAM Roles**: Service account integration
- **EBS Encryption**: Encrypted storage volumes
- **VPC Flow Logs**: Network traffic monitoring
- **CloudTrail**: API call logging

## Scalability Architecture

### Horizontal Scaling
- **EKS Auto Scaling**: Node group scaling
- **HPA**: Pod-level autoscaling
- **Load Balancer**: Traffic distribution
- **Multi-AZ**: Availability zone distribution

### Vertical Scaling
- **Resource Limits**: CPU and memory constraints
- **Instance Types**: Configurable node sizes
- **Storage Scaling**: EBS volume expansion
- **Performance Tuning**: Application-level optimization

## Monitoring & Observability

### Metrics Collection
- **Prometheus**: Metrics scraping and storage
- **Grafana**: Visualization and dashboards
- **Application Metrics**: Custom s3www metrics
- **Infrastructure Metrics**: Node and cluster metrics

### Logging
- **Container Logs**: Application and system logs
- **CloudWatch**: Centralized log aggregation
- **Structured Logging**: JSON-formatted logs
- **Log Retention**: Configurable retention policies

### Alerting
- **Prometheus Alerts**: Metric-based alerting
- **CloudWatch Alarms**: AWS service monitoring
- **SLA Monitoring**: Performance and availability
- **Incident Response**: Automated notifications

## Disaster Recovery

### Backup Strategy
- **Velero**: Kubernetes resource backup
- **EBS Snapshots**: Volume-level backups
- **S3 Replication**: Cross-region data replication
- **Configuration Backup**: Terraform state and configs

### Recovery Procedures
- **RTO/RPO**: Recovery time and point objectives
- **Multi-Region**: Cross-region failover capability
- **Data Restoration**: Automated restore procedures
- **Testing**: Regular disaster recovery testing

## Cost Optimization

### Resource Optimization
- **Auto Scaling**: Scale to zero capabilities
- **Instance Types**: Right-sized compute resources
- **Storage Classes**: Cost-effective storage options
- **Reserved Instances**: Long-term cost savings

### Monitoring & Alerts
- **Cost Monitoring**: AWS Cost Explorer integration
- **Budget Alerts**: Spending threshold notifications
- **Resource Tagging**: Cost allocation and tracking
- **Optimization Recommendations**: Automated suggestions

## Environment Strategy

### Development Environment
- **Minimal Resources**: Cost-optimized configuration
- **Debug Mode**: Enhanced logging and debugging
- **Local Development**: Docker Compose for local testing
- **Quick Iteration**: Fast deployment cycles

### Production Environment
- **High Availability**: Multi-AZ deployment
- **Security Hardening**: Enhanced security measures
- **Monitoring**: Comprehensive observability
- **Backup & Recovery**: Full disaster recovery capability

### Staging Environment
- **Production Parity**: Similar to production configuration
- **Testing**: Integration and performance testing
- **Validation**: Deployment validation and verification
- **Rollback**: Safe rollback procedures

## Technology Stack

### Infrastructure
- **Terraform**: Infrastructure as Code
- **AWS EKS**: Managed Kubernetes
- **AWS VPC**: Network infrastructure
- **AWS EBS**: Block storage

### Applications
- **Helm**: Kubernetes package management
- **MinIO**: S3-compatible object storage
- **s3www**: Go-based web server
- **Alpine Linux**: Container base images

### Monitoring & Operations
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Velero**: Backup and restore
- **kubectl**: Kubernetes management

### Security
- **AWS IAM**: Identity and access management
- **AWS Secrets Manager**: Secret storage
- **Kubernetes RBAC**: Role-based access control
- **Pod Security Standards**: Security policies

---

This architecture provides a robust, scalable, and production-ready foundation for deploying the s3www application with MinIO dependency on AWS EKS. 