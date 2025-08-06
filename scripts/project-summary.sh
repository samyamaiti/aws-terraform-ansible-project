#!/bin/bash

# Project Summary and Quick Test Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo_color() {
    echo -e "${1}${2}${NC}"
}

echo_color $PURPLE "🚀 AWS Terraform Ansible Project with EKS and Microservices"
echo_color $PURPLE "============================================================="
echo ""

echo_color $BLUE "📋 Project Summary:"
echo_color $GREEN "✅ EC2 Infrastructure: 10 configurable EC2 instances with automatic software installation"
echo_color $GREEN "✅ EKS Cluster: Managed Kubernetes cluster with 2 worker nodes (conditional deployment)"
echo_color $GREEN "✅ Spring Boot Microservice: RESTful API with health checks and metrics"
echo_color $GREEN "✅ Docker Containerization: Multi-stage builds with health checks"
echo_color $GREEN "✅ Kubernetes Deployment: Complete manifests with services and ingress"
echo_color $GREEN "✅ ECR Integration: Automatic Docker image push and deployment"
echo_color $GREEN "✅ Infrastructure as Code: Full Terraform automation"
echo_color $GREEN "✅ Configuration Management: Ansible playbooks for software installation"
echo_color $GREEN "✅ Integrated Pipeline: Single-command deployment from infrastructure to application"
echo ""

echo_color $BLUE "🏗️ Architecture Components:"
echo_color $YELLOW "Infrastructure Layer:"
echo "  • AWS VPC with public subnets"
echo "  • EC2 instances with security groups"
echo "  • EKS cluster with IAM roles"
echo "  • ECR repository for container images"
echo ""
echo_color $YELLOW "Application Layer:"
echo "  • Java 17 Spring Boot microservice"
echo "  • REST API endpoints (/, /health, /hello/{name}, /info)"
echo "  • Spring Boot Actuator for monitoring"
echo "  • Docker containerization with health checks"
echo ""
echo_color $YELLOW "Deployment Layer:"
echo "  • Terraform for infrastructure provisioning"
echo "  • Ansible for configuration management"
echo "  • Kubernetes for container orchestration"
echo "  • Automated CI/CD pipeline"
echo ""

echo_color $BLUE "🛠️ Available Scripts:"
echo_color $GREEN "./scripts/deploy-complete.sh --eks" 
echo "  └─ Complete deployment (EC2 + EKS + Microservice)"
echo_color $GREEN "./scripts/deploy-complete.sh"
echo "  └─ EC2-only deployment"  
echo_color $GREEN "./scripts/deploy-complete.sh --cleanup"
echo "  └─ Destroy all resources"
echo_color $GREEN "./microservice/build-deploy.sh ecr"
echo "  └─ Build and deploy microservice to EKS"
echo_color $GREEN "./scripts/validate.sh"
echo "  └─ Validate deployment and prerequisites"
echo ""

echo_color $BLUE "🔧 Quick Test Commands:"
echo_color $YELLOW "Local Development:"
echo "cd microservice && mvn spring-boot:run"
echo "curl http://localhost:8080/health"
echo ""
echo_color $YELLOW "Deployed Service (after EKS deployment):"
echo "kubectl port-forward service/demo-microservice-service 8080:80"
echo "curl http://localhost:8080/health"
echo ""
echo_color $YELLOW "Monitor Kubernetes:"
echo "kubectl get nodes"
echo "kubectl get deployments"
echo "kubectl get services"
echo "kubectl logs -l app=demo-microservice --tail=50"
echo ""

echo_color $BLUE "📁 Key Files Created:"
echo_color $GREEN "Infrastructure:"
echo "  • terraform/main.tf - EC2 instances and networking"
echo "  • terraform/eks.tf - EKS cluster configuration"
echo "  • terraform/variables.tf - Configurable parameters"
echo ""
echo_color $GREEN "Application:"
echo "  • microservice/src/main/java/com/example/demo/ - Spring Boot application"
echo "  • microservice/Dockerfile - Container configuration"
echo "  • microservice/k8s/deployment.yaml - Kubernetes manifests"
echo "  • microservice/pom.xml - Maven build configuration"
echo ""
echo_color $GREEN "Automation:"
echo "  • ansible/playbooks/install-software.yml - EC2 software installation"
echo "  • ansible/playbooks/deploy-microservice.yml - Kubernetes deployment"
echo "  • scripts/deploy-complete.sh - End-to-end deployment"
echo ""

echo_color $BLUE "🚀 Next Steps:"
echo "1. Configure terraform/terraform.tfvars with your AWS settings"
echo "2. Ensure AWS CLI is configured: aws configure"
echo "3. Run: ./scripts/deploy-complete.sh --eks"
echo "4. Wait for deployment to complete (~10-15 minutes)"
echo "5. Test the microservice endpoints"
echo ""

echo_color $BLUE "💡 Features Highlights:"
echo_color $GREEN "• Single-command deployment from zero to running microservice"
echo_color $GREEN "• Conditional EKS deployment (can deploy with or without Kubernetes)"
echo_color $GREEN "• Fully automated Docker build, push, and deploy pipeline"
echo_color $GREEN "• Health checks and monitoring built into the application"
echo_color $GREEN "• Production-ready Kubernetes configurations"
echo_color $GREEN "• Comprehensive error handling and validation"
echo_color $GREEN "• Clean separation between infrastructure and application code"
echo ""

echo_color $PURPLE "Ready to deploy! 🎉"
echo_color $YELLOW "Run './scripts/deploy-complete.sh --help' for detailed options"
