# AWS Terraform Ansible Project with EKS and Microservices

This project provisions AWS infrastructure including EC2 instances and an EKS cluster using Terraform, and uses Ansible to automatically install software and deploy a Java Spring Boot microservice to Kubernetes.

## Project Structure

```
aws-terraform-ansible-project/
├── README.md
├── requirements.txt
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── aws_ec2.yml
│   │   └── hosts.tpl
│   └── playbooks/
│       ├── install-software.yml
│       └── deploy-microservice.yml
├── microservice/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── build-deploy.sh
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/demo/
│   │   │   │   ├── DemoApplication.java
│   │   │   │   └── controller/HelloController.java
│   │   │   └── resources/
│   │   │       └── application.properties
│   │   └── test/
│   │       └── java/com/example/demo/controller/
│   │           └── HelloControllerTest.java
│   └── k8s/
│       └── deployment.yaml
├── scripts/
│   ├── demo.sh
│   ├── deploy-integrated.sh
│   ├── deploy.sh
│   ├── deploy-complete.sh
│   └── validate.sh
└── terraform/
    ├── main.tf
    ├── eks.tf
    ├── outputs.tf
    ├── terraform.tfvars
    ├── terraform.tfvars.example
    ├── variables.tf
    └── versions.tf
```

## Features

### Infrastructure
- ✅ **EC2 Instances**: Provisions configurable number of EC2 instances
- ✅ **EKS Cluster**: Optional managed Kubernetes cluster with worker nodes
- ✅ **VPC & Networking**: Complete network setup with subnets and security groups
- ✅ **IAM Roles**: Proper IAM roles for EKS cluster and worker nodes

### Application
- ✅ **Spring Boot Microservice**: REST API with health checks and metrics
- ✅ **Docker Containerization**: Multi-stage Docker build with health checks
- ✅ **Kubernetes Deployment**: Complete K8s manifests with services and ingress
- ✅ **ECR Integration**: Automatic Docker image push to AWS ECR

### Automation
- ✅ **Integrated Deployment**: Single script deployment with Terraform + Ansible
- ✅ **Software Installation**: Automatic Java and Python installation via Ansible
- ✅ **Microservice Deployment**: Automated build, push, and deploy to EKS
- ✅ **Health Monitoring**: Built-in health checks and monitoring endpoints

## Prerequisites

### Required Tools
- **AWS CLI** (>= 2.0) - configured with appropriate credentials
- **Terraform** (>= 1.5) - infrastructure as code
- **Ansible** (>= 2.9) - configuration management
- **Docker** (>= 20.0) - containerization
- **kubectl** (>= 1.25) - Kubernetes CLI
- **Maven** (>= 3.6) - Java build tool
- **Java** (>= 17) - for local development

### AWS Permissions
Your AWS user/role needs permissions for:
- EC2 (instances, VPC, security groups)
- EKS (cluster, node groups)
- ECR (repositories, images)
- IAM (roles, policies)

## Quick Start

### 1. Complete Infrastructure + Microservice Deployment

```bash
# Deploy everything (EC2 + EKS + Microservice)
./scripts/deploy-complete.sh --eks

# Deploy only EC2 instances
./scripts/deploy-complete.sh

# Clean up all resources
./scripts/deploy-complete.sh --cleanup
```

### 2. Step-by-Step Deployment

#### Configure Variables
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your settings
```

#### Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### Deploy Microservice (if EKS is enabled)
```bash
cd microservice
./build-deploy.sh ecr  # Deploy to ECR + EKS
# or
./build-deploy.sh      # Local deployment
```

## Configuration

### Terraform Variables (`terraform.tfvars`)

```hcl
# Basic Configuration
aws_region = "us-west-2"
vpc_cidr = "10.0.0.0/16"
key_name = "your-key-pair"

# EC2 Configuration
instance_count = 10
instance_type = "t3.micro"

# EKS Configuration
deploy_eks = true                    # Set to false to skip EKS
eks_cluster_version = "1.27"
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size = 2
eks_node_max_size = 4
eks_node_min_size = 1

# Tags
project_name = "aws-terraform-ansible"
environment = "demo"
```

### Microservice Configuration

The Spring Boot microservice includes:
- **REST Endpoints**:
  - `GET /` - Welcome message with service info
  - `GET /health` - Health check endpoint
  - `GET /hello/{name}` - Personalized greeting
  - `GET /info` - Service information
- **Actuator Endpoints**: `/actuator/health`, `/actuator/info`, `/actuator/metrics`
- **Kubernetes Probes**: Liveness and readiness probes configured

## Usage Examples

### Test the Microservice Locally

```bash
cd microservice
mvn spring-boot:run

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/hello/World
curl http://localhost:8080/actuator/health
```

### Access the Deployed Microservice

```bash
# Port forward to access the service
kubectl port-forward service/demo-microservice-service 8080:80

# Test the deployed service
curl http://localhost:8080/health
curl http://localhost:8080/hello/Kubernetes
```

### Monitor the Deployment

```bash
# Check EKS cluster status
kubectl get nodes
kubectl get deployments
kubectl get services
kubectl get pods

# View logs
kubectl logs -l app=demo-microservice --tail=100

# Describe deployment
kubectl describe deployment demo-microservice
```

## Outputs

After deployment, you'll receive:

### EC2 Infrastructure
- EC2 instance public IPs
- SSH connection commands
- VPC and subnet information

### EKS Cluster (if enabled)
- EKS cluster endpoint
- EKS cluster name
- kubectl configuration commands

### Microservice (if deployed)
- Service URLs and endpoints
- Load balancer information
- Health check status

## Troubleshooting

### Common Issues

**EKS Cluster Not Ready**
```bash
# Check cluster status
aws eks describe-cluster --region us-west-2 --name demo-eks-cluster

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name demo-eks-cluster
```

**Microservice Not Accessible**
```bash
# Check pod status
kubectl get pods -l app=demo-microservice

# Check service
kubectl get service demo-microservice-service

# Check logs
kubectl logs -l app=demo-microservice --tail=50
```

**Docker Build Fails**
```bash
# Build locally first
cd microservice
mvn clean package
docker build -t demo-microservice:latest .
```

### Validation Scripts

```bash
# Validate overall deployment
./scripts/validate.sh

# Check prerequisites
./scripts/deploy-complete.sh -h
```

## Development

### Local Development Setup

```bash
cd microservice
mvn clean install
mvn test
mvn spring-boot:run
```

### Adding New Endpoints

1. Create new controller methods in `HelloController.java`
2. Add corresponding tests in `HelloControllerTest.java`
3. Rebuild and redeploy using `./build-deploy.sh`

### Modifying Infrastructure

1. Update Terraform variables in `terraform.tfvars`
2. Modify resources in `terraform/*.tf` files
3. Apply changes: `terraform plan && terraform apply`

## Cleanup

### Destroy All Resources

```bash
./scripts/deploy-complete.sh --cleanup
```

### Manual Cleanup

```bash
# Destroy Terraform resources
cd terraform
terraform destroy -var-file="terraform.tfvars" -auto-approve

# Clean up Docker images (optional)
docker rmi demo-microservice:latest
docker system prune -f
```

## Architecture

This project implements a complete DevOps pipeline with:

1. **Infrastructure as Code** (Terraform) - Provisions AWS resources
2. **Configuration Management** (Ansible) - Configures instances and deploys applications
3. **Containerization** (Docker) - Packages the microservice
4. **Orchestration** (Kubernetes/EKS) - Manages container deployment
5. **CI/CD Integration** - Automated build, test, and deployment pipeline

The architecture supports both traditional EC2-based deployments and modern container-based deployments on Kubernetes, providing flexibility for different use cases and migration strategies.
