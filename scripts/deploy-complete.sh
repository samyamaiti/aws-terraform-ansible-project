#!/bin/bash

# Comprehensive deployment script for AWS infrastructure with EKS and microservice
set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
ANSIBLE_DIR="$PROJECT_DIR/ansible"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_color() {
    echo -e "${1}${2}${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    echo_color $BLUE "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v mvn &> /dev/null; then
        missing_tools+=("maven")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo_color $RED "Missing required tools: ${missing_tools[*]}"
        echo_color $YELLOW "Please install the missing tools and run this script again."
        exit 1
    fi
    
    echo_color $GREEN "All prerequisites are installed!"
}

# Function to validate AWS credentials
check_aws_credentials() {
    echo_color $BLUE "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo_color $RED "AWS credentials are not configured or invalid."
        echo_color $YELLOW "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    echo_color $GREEN "AWS credentials are valid!"
}

# Function to initialize Terraform
init_terraform() {
    echo_color $BLUE "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    
    terraform init
    terraform validate
    
    echo_color $GREEN "Terraform initialized successfully!"
}

# Function to plan Terraform deployment
plan_terraform() {
    echo_color $BLUE "Planning Terraform deployment..."
    cd "$TERRAFORM_DIR"
    
    terraform plan -var-file="terraform.tfvars" -out=tfplan
    
    echo_color $YELLOW "Review the Terraform plan above."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_color $YELLOW "Deployment cancelled."
        exit 0
    fi
}

# Function to apply Terraform configuration
apply_terraform() {
    echo_color $BLUE "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"
    
    terraform apply tfplan
    
    echo_color $GREEN "Terraform deployment completed!"
}

# Function to configure kubectl for EKS
configure_kubectl() {
    if [ "$DEPLOY_EKS" = "true" ]; then
        echo_color $BLUE "Configuring kubectl for EKS cluster..."
        
        local cluster_name=$(terraform -chdir="$TERRAFORM_DIR" output -raw eks_cluster_name 2>/dev/null || echo "")
        local aws_region=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws_region 2>/dev/null || echo "us-west-2")
        
        if [ ! -z "$cluster_name" ]; then
            aws eks update-kubeconfig --region "$aws_region" --name "$cluster_name"
            echo_color $GREEN "kubectl configured for EKS cluster: $cluster_name"
        else
            echo_color $YELLOW "EKS cluster name not found in outputs, skipping kubectl configuration"
        fi
    fi
}

# Function to wait for EKS cluster to be ready
wait_for_eks() {
    if [ "$DEPLOY_EKS" = "true" ]; then
        echo_color $BLUE "Waiting for EKS cluster to be ready..."
        
        local cluster_name=$(terraform -chdir="$TERRAFORM_DIR" output -raw eks_cluster_name 2>/dev/null || echo "")
        local aws_region=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws_region 2>/dev/null || echo "us-west-2")
        
        if [ ! -z "$cluster_name" ]; then
            aws eks wait cluster-active --region "$aws_region" --name "$cluster_name"
            echo_color $GREEN "EKS cluster is ready!"
            
            # Wait for nodes to be ready
            echo_color $BLUE "Waiting for EKS nodes to be ready..."
            kubectl wait --for=condition=Ready nodes --all --timeout=300s
            echo_color $GREEN "EKS nodes are ready!"
        fi
    fi
}

# Function to show deployment outputs
show_outputs() {
    echo_color $BLUE "Deployment Summary:"
    cd "$TERRAFORM_DIR"
    
    echo_color $YELLOW "=== EC2 Instances ==="
    terraform output ec2_public_ips 2>/dev/null || echo "No EC2 outputs available"
    
    if [ "$DEPLOY_EKS" = "true" ]; then
        echo_color $YELLOW "=== EKS Cluster ==="
        terraform output eks_cluster_endpoint 2>/dev/null || echo "No EKS outputs available"
        terraform output eks_cluster_name 2>/dev/null || echo "No EKS cluster name available"
        
        echo_color $YELLOW "=== Kubernetes Resources ==="
        kubectl get nodes 2>/dev/null || echo "Unable to connect to Kubernetes cluster"
        kubectl get deployments --all-namespaces 2>/dev/null || echo "No deployments found"
        kubectl get services --all-namespaces 2>/dev/null || echo "No services found"
    fi
    
    echo_color $GREEN "Deployment completed successfully!"
}

# Function to clean up resources
cleanup() {
    echo_color $YELLOW "Cleaning up resources..."
    cd "$TERRAFORM_DIR"
    
    read -p "This will destroy all created resources. Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform destroy -var-file="terraform.tfvars" -auto-approve
        echo_color $GREEN "Resources cleaned up successfully!"
    else
        echo_color $YELLOW "Cleanup cancelled."
    fi
}

# Main execution
main() {
    echo_color $GREEN "Starting AWS Infrastructure Deployment with EKS and Microservice"
    echo_color $GREEN "============================================================"
    
    # Parse command line arguments
    DEPLOY_EKS="false"
    CLEANUP="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --eks)
                DEPLOY_EKS="true"
                shift
                ;;
            --cleanup)
                CLEANUP="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --eks      Deploy EKS cluster and microservice"
                echo "  --cleanup  Destroy all resources"
                echo "  -h, --help Show this help message"
                exit 0
                ;;
            *)
                echo_color $RED "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$CLEANUP" = "true" ]; then
        cleanup
        exit 0
    fi
    
    # Update terraform.tfvars to enable/disable EKS
    if [ "$DEPLOY_EKS" = "true" ]; then
        sed -i '' 's/deploy_eks = false/deploy_eks = true/' "$TERRAFORM_DIR/terraform.tfvars" 2>/dev/null || true
        echo_color $GREEN "EKS deployment enabled"
    else
        sed -i '' 's/deploy_eks = true/deploy_eks = false/' "$TERRAFORM_DIR/terraform.tfvars" 2>/dev/null || true
        echo_color $YELLOW "EKS deployment disabled"
    fi
    
    # Execute deployment steps
    check_prerequisites
    check_aws_credentials
    init_terraform
    plan_terraform
    apply_terraform
    
    if [ "$DEPLOY_EKS" = "true" ]; then
        configure_kubectl
        wait_for_eks
    fi
    
    show_outputs
    
    echo_color $GREEN "Deployment process completed!"
    
    if [ "$DEPLOY_EKS" = "true" ]; then
        echo_color $YELLOW "To access your microservice:"
        echo_color $YELLOW "kubectl port-forward service/demo-microservice-service 8080:80"
        echo_color $YELLOW "curl http://localhost:8080/health"
    fi
}

# Run main function with all arguments
main "$@"
