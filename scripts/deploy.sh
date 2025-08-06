#!/bin/bash

# AWS Terraform Ansible Deployment Script
# This script automates the deployment of EC2 instances and software installation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Ansible is installed
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration and run the script again."
        exit 1
    fi
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Infrastructure deployed successfully!"
    
    cd ..
}

# Function to configure instances with Ansible
configure_instances() {
    print_status "Configuring instances with Ansible..."
    
    cd ansible
    
    # Wait for instances to be ready
    print_status "Waiting for instances to be ready (60 seconds)..."
    sleep 60
    
    # Test connectivity
    print_status "Testing connectivity to instances..."
    if ! ansible all -m ping; then
        print_error "Cannot connect to instances. Check your SSH configuration."
        exit 1
    fi
    
    # Run the playbook
    print_status "Running software installation playbook..."
    ansible-playbook playbooks/install-software.yml -v
    
    print_success "Instance configuration completed!"
    
    cd ..
}

# Function to show deployment information
show_deployment_info() {
    print_status "Deployment Information:"
    echo "======================="
    
    cd terraform
    
    echo "Public IP Addresses:"
    terraform output -json instance_public_ips | jq -r '.[]'
    
    echo ""
    echo "SSH Connection Commands:"
    terraform output -json ssh_connection_commands | jq -r '.[]'
    
    echo ""
    print_success "Deployment completed successfully!"
    print_status "You can now SSH into your instances and verify Java/Python installations."
    
    cd ..
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_warning "This will destroy all created resources. Are you sure? (yes/no)"
    read -r confirmation
    
    if [ "$confirmation" = "yes" ]; then
        print_status "Destroying infrastructure..."
        cd terraform
        terraform destroy -auto-approve
        cd ..
        print_success "Infrastructure destroyed successfully!"
    else
        print_status "Destruction cancelled."
    fi
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        print_status "Starting full deployment..."
        check_prerequisites
        deploy_infrastructure
        configure_instances
        show_deployment_info
        ;;
    "infrastructure")
        print_status "Deploying infrastructure only..."
        check_prerequisites
        deploy_infrastructure
        ;;
    "configure")
        print_status "Configuring instances only..."
        check_prerequisites
        configure_instances
        ;;
    "destroy")
        destroy_infrastructure
        ;;
    "info")
        show_deployment_info
        ;;
    *)
        echo "Usage: $0 {deploy|infrastructure|configure|destroy|info}"
        echo "  deploy        - Full deployment (infrastructure + configuration)"
        echo "  infrastructure- Deploy infrastructure only"
        echo "  configure     - Configure instances only"
        echo "  destroy       - Destroy all resources"
        echo "  info          - Show deployment information"
        exit 1
        ;;
esac
