# GitHub Actions CI/CD Setup

This document explains how to set up and use the GitHub Actions workflows for automated deployment and monitoring of your AWS infrastructure.

## 🚀 **Workflows Overview**

### 1. **Main CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
- **Triggers**: Push to main/develop, Pull requests, Manual dispatch
- **Features**: 
  - Code validation and security scanning
  - Microservice testing and Docker builds
  - Infrastructure planning and deployment
  - EKS cluster management
  - Automated cleanup options

### 2. **Infrastructure Monitoring** (`.github/workflows/monitoring.yml`)
- **Triggers**: Daily schedule (6 AM UTC), Manual dispatch
- **Features**:
  - Health checks for EC2 and EKS
  - Application endpoint monitoring
  - Security compliance scanning
  - Cost analysis and resource inventory

### 3. **Resource Cleanup** (`.github/workflows/cleanup.yml`)
- **Triggers**: Weekly schedule (Sunday 2 AM UTC), Manual dispatch
- **Features**:
  - Automatic cleanup of test/dev resources older than 7 days
  - ECR image cleanup
  - Orphaned resource detection
  - Dry run mode for safe testing

## ⚙️ **Required Secrets Setup**

Before using the workflows, you need to configure these GitHub repository secrets:

### AWS Configuration
```bash
AWS_ACCESS_KEY_ID          # AWS access key with required permissions
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_KEY_PAIR_NAME          # Name of your AWS EC2 key pair
AWS_PRIVATE_KEY            # Contents of your EC2 private key (.pem file)
```

### Optional Integrations
```bash
SLACK_WEBHOOK_URL          # Slack webhook for notifications (optional)
```

### How to Add Secrets
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name and value

## 🛡️ **Required AWS Permissions**

Your AWS user/role needs these permissions:

### Core Permissions
- **EC2**: Full access for instances, VPC, security groups, key pairs
- **EKS**: Full access for cluster and node group management
- **ECR**: Full access for container registry
- **IAM**: Create/manage roles and policies for EKS
- **CloudWatch**: Read access for monitoring

### Cost Explorer (Optional)
- **ce:GetCostAndUsage**: For cost monitoring workflow

### Example IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "ecr:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRoles",
        "cloudwatch:GetMetricStatistics",
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚦 **Usage Examples**

### Manual Deployment
1. Go to **Actions** tab in GitHub
2. Select **AWS Infrastructure CI/CD Pipeline**
3. Click **Run workflow**
4. Configure options:
   - **Deploy EKS**: `true` for full stack, `false` for EC2 only
   - **Environment**: `dev`, `staging`, or `prod`
   - **Destroy**: `true` to cleanup after deployment (testing)

### Pull Request Workflow
1. Create a feature branch
2. Make changes to infrastructure or application code
3. Create a pull request to `main`
4. Workflow automatically runs validation and shows Terraform plan
5. Review changes before merging

### Monitoring Check
1. Go to **Actions** tab
2. Select **Infrastructure Monitoring**
3. Click **Run workflow**
4. Select check type: `health`, `security`, `costs`, or `all`

## 📊 **Workflow Stages Explained**

### Validation Stage
```yaml
- Syntax validation for Terraform and Ansible
- Security scanning with tfsec
- Code formatting checks
- Dependency validation
```

### Testing Stage
```yaml
- Maven unit tests for Spring Boot app
- Docker image build and test
- Application health endpoint verification
- Test result artifacts upload
```

### Planning Stage
```yaml
- Terraform plan generation
- Cost estimation (if enabled)
- Plan artifact storage
- Pull request comments with changes
```

### Deployment Stage
```yaml
- Terraform apply with approval gates
- Ansible configuration management
- EKS cluster setup and app deployment
- Health checks and validation
- Output collection and reporting
```

## 🔧 **Customization Options**

### Environment-Specific Variables
Edit the workflow files to customize per environment:

```yaml
# In ci-cd.yml, modify the "Create Terraform Variables File" step
instance_count = 2              # Number of EC2 instances
instance_type = "t3.micro"      # Instance type
eks_node_desired_size = 1       # EKS node count
eks_node_instance_types = ["t3.medium"]
```

### Notification Settings
Add Slack notifications by setting up the webhook URL:

```yaml
# Add this to any job for Slack notifications
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    fields: repo,message,commit,author,action
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Custom Schedules
Modify cron expressions for different schedules:

```yaml
on:
  schedule:
    - cron: '0 6 * * *'        # Daily at 6 AM
    - cron: '0 2 * * 0'        # Weekly on Sunday at 2 AM
    - cron: '0 9 * * 1-5'      # Weekdays at 9 AM
```

## 🎯 **Best Practices**

### Security
- ✅ Use GitHub repository secrets for sensitive data
- ✅ Implement approval gates for production deployments
- ✅ Regular security scanning and compliance checks
- ✅ Principle of least privilege for AWS permissions

### Cost Management
- ✅ Automatic cleanup of test resources
- ✅ Resource tagging for cost allocation
- ✅ Regular cost monitoring and alerts
- ✅ Right-sizing recommendations

### Reliability
- ✅ Multiple environment support (dev/staging/prod)
- ✅ Rollback capabilities
- ✅ Health checks and monitoring
- ✅ Artifact storage for debugging

### Efficiency
- ✅ Parallel job execution where possible
- ✅ Caching for dependencies (Maven, Docker layers)
- ✅ Conditional execution based on changes
- ✅ Reusable workflow components

## 🐛 **Troubleshooting**

### Common Issues

**Workflow fails with AWS permissions error**
```bash
# Solution: Check AWS credentials and permissions
# Verify secrets are set correctly in GitHub
# Ensure IAM user has required permissions
```

**Terraform state lock issues**
```bash
# Solution: Use remote state backend (S3 + DynamoDB)
# Add backend configuration to main.tf
# Enable state locking for concurrent runs
```

**EKS cluster creation timeout**
```bash
# Solution: Increase timeout values
# Check AWS service limits
# Verify VPC and subnet configuration
```

**Application deployment fails**
```bash
# Solution: Check Docker image build
# Verify ECR permissions and repository exists
# Check Kubernetes manifests syntax
```

### Debugging Steps
1. **Check workflow logs** in GitHub Actions tab
2. **Review artifact uploads** for detailed reports
3. **Verify AWS console** for resource status
4. **Test locally** using the same scripts
5. **Check resource quotas** and limits

### Getting Help
- Review workflow logs and artifacts
- Check the main project README for configuration
- Use GitHub Issues for bug reports
- Test changes in a feature branch first

## 📈 **Monitoring and Alerts**

### Available Reports
- **Health Reports**: Infrastructure and application status
- **Security Reports**: Compliance and vulnerability scans  
- **Cost Reports**: Resource usage and spending analysis
- **Cleanup Reports**: Resource maintenance activities

### Setting Up Alerts
1. Configure Slack webhook for immediate notifications
2. Set up GitHub Issues for failed health checks
3. Use AWS CloudWatch for infrastructure monitoring
4. Configure cost budgets and alerts in AWS

### Metrics Tracking
- Deployment success/failure rates
- Infrastructure costs over time
- Application performance metrics
- Security compliance scores

This completes the GitHub Actions setup guide. The workflows provide a complete CI/CD pipeline with monitoring and maintenance capabilities for your AWS infrastructure project.
