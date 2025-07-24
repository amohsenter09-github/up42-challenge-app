# 🤝 Contributing Guide

Thank you for your interest in contributing to the UP42 Challenge Application! This guide will help you understand how to contribute effectively.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Code of Conduct](#code-of-conduct)

## 🚀 Getting Started

### Prerequisites

- **AWS CLI** with appropriate permissions
- **Terraform** (v1.0+)
- **kubectl** configured for your cluster
- **Helm** (v3.0+)
- **Docker** for local development
- **Go** (v1.19+) for s3www application development

### Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/your-username/up42-challenge-app.git
cd up42-challenge-app

# Add upstream remote
git remote add upstream https://github.com/original-owner/up42-challenge-app.git
```

## 🔧 Development Setup

### Local Development Environment

```bash
# Set up local development
cd terraform
./deploy.sh all dev

# Or use Docker Compose for local testing
docker-compose up -d
```

### Development Workflow

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test your changes
./deploy.sh applications dev

# Commit your changes
git add .
git commit -m "feat: add your feature description"

# Push to your fork
git push origin feature/your-feature-name
```

## 📝 Code Standards

### Terraform Standards

- **File Naming**: Use snake_case for file names
- **Variable Naming**: Use snake_case for variables
- **Resource Naming**: Use kebab-case for resource names
- **Documentation**: Include descriptions for all variables and outputs
- **Formatting**: Run `terraform fmt` before committing

```bash
# Format Terraform code
terraform fmt -recursive

# Validate Terraform code
terraform validate
```

### Helm Chart Standards

- **Chart Structure**: Follow Helm best practices
- **Values Documentation**: Document all configurable values
- **Templates**: Use consistent indentation and naming
- **Testing**: Test templates with `helm template`

```bash
# Test Helm templates
helm template s3www-app ./helm/s3www-app

# Lint Helm chart
helm lint ./helm/s3www-app
```

### Kubernetes Standards

- **Resource Naming**: Use consistent naming conventions
- **Labels**: Apply appropriate labels and annotations
- **Security**: Follow security best practices
- **Resource Limits**: Always specify resource requests and limits

### Documentation Standards

- **README Files**: Keep documentation up to date
- **Code Comments**: Add comments for complex logic
- **Examples**: Provide working examples
- **Screenshots**: Include screenshots for UI changes

## 🧪 Testing

### Infrastructure Testing

```bash
# Test Terraform plan
terraform plan -var-file=environments/dev.tfvars

# Test deployment
./deploy.sh all dev

# Verify deployment
./deploy.sh status dev

# Clean up
./deploy.sh destroy dev
```

### Application Testing

```bash
# Test s3www application
curl http://localhost:8080

# Test MinIO connectivity
kubectl exec -it deployment/s3www-app-deployment -- curl minio:9000

# Test file upload/download
# (Add your specific test cases)
```

### Integration Testing

```bash
# Run full integration test
./scripts/test-integration.sh

# Test different environments
./deploy.sh all production
./deploy.sh all dev
```

## 🔄 Pull Request Process

### Before Submitting

1. **Test Your Changes**: Ensure all tests pass
2. **Update Documentation**: Update relevant documentation
3. **Check Formatting**: Run formatting tools
4. **Review Your Code**: Self-review your changes

### Pull Request Guidelines

1. **Clear Title**: Use descriptive PR titles
2. **Detailed Description**: Explain what and why, not how
3. **Related Issues**: Link to related issues
4. **Screenshots**: Include screenshots for UI changes
5. **Testing**: Describe how you tested your changes

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

## 🐛 Issue Reporting

### Before Creating an Issue

1. **Search Existing Issues**: Check if the issue already exists
2. **Reproduce the Problem**: Ensure you can reproduce it consistently
3. **Gather Information**: Collect relevant logs and information

### Issue Template

```markdown
## Description
Clear description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Environment
- OS: [e.g., macOS, Linux]
- Terraform Version: [e.g., 1.0.0]
- Kubernetes Version: [e.g., 1.24]
- AWS Region: [e.g., us-west-2]

## Additional Information
- Logs, screenshots, etc.
```

## 📚 Development Resources

### Documentation

- [Terraform Documentation](https://www.terraform.io/docs)
- [Helm Documentation](https://helm.sh/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks)

### Tools

- **Terraform**: Infrastructure as Code
- **Helm**: Kubernetes package manager
- **kubectl**: Kubernetes command-line tool
- **AWS CLI**: AWS command-line interface

### Best Practices

- **Infrastructure as Code**: All infrastructure should be version controlled
- **Security First**: Follow security best practices
- **Monitoring**: Include monitoring and observability
- **Documentation**: Keep documentation up to date

## 🚨 Code of Conduct

### Our Standards

- **Respectful Communication**: Be respectful and inclusive
- **Constructive Feedback**: Provide constructive feedback
- **Collaboration**: Work together to improve the project
- **Learning**: Help others learn and grow

### Unacceptable Behavior

- **Harassment**: Any form of harassment or discrimination
- **Trolling**: Deliberate disruption or trolling
- **Spam**: Unwanted promotional content
- **Inappropriate Content**: Offensive or inappropriate content

## 🎯 Getting Help

### Community Support

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and discussions
- **Documentation**: Check existing documentation first

### Contact Information

- **Maintainers**: [@maintainer-username]
- **Email**: [project-email@example.com]
- **Slack**: [project-slack-channel]

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing! 🎉** 