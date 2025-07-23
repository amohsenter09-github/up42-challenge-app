#!/bin/bash
# Bootstrap script to set up S3 backend for Terraform state management
# Simplified version without DynamoDB locking

set -e

# Configuration
REGION="eu-west-1"
PROJECT_NAME="up42-challenge"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(openssl rand -hex 8)"

echo "🚀 Bootstrapping Terraform S3 Backend..."
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Create S3 bucket
echo "📦 Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning on the S3 bucket
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔒 Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
echo "🚫 Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create backend configuration file
echo "📝 Creating backend configuration..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket  = "$BUCKET_NAME"
    key     = "terraform.tfstate"
    region  = "$REGION"
    encrypt = true
  }
}
EOF

echo "✅ Bootstrap completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Initialize Terraform with the new backend:"
echo "   terraform init"
echo ""
echo "2. Plan and apply your infrastructure:"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "📁 Backend configuration saved to: backend.tf"
echo "🪣 S3 Bucket: $BUCKET_NAME"
echo "�� Region: $REGION" 