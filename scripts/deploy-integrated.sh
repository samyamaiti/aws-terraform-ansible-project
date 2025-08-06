#!/bin/bash

# Enhanced AWS Terraform Ansible Deployment Script
# This script automates the deployment with integrated Ansible execution

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
    
    # Check if Ansible is installed (only if we're running Ansible)
    if [ "${1:-true}" = "true" ] && ! command -v ansible &> /dev/null; then
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

# Function to deploy infrastructure with integrated Ansible
deploy_integrated() {
    local run_ansible=${1:-true}
    
    print_status "Starting integrated deployment (Terraform + Ansible)..."
    
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
    if [ "$run_ansible" = "false" ]; then
        terraform plan -var="run_ansible=false" -out=tfplan
    else
        terraform plan -out=tfplan
    fi
    
    # Apply deployment (this will also run Ansible if enabled)
    print_status "Applying Terraform configuration..."
    if [ "$run_ansible" = "true" ]; then
        print_status "This will automatically run Ansible after provisioning instances..."
        print_status "Instances will be configured with Java and Python automatically!"
    fi
    
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Integrated deployment completed successfully!"
    
    cd ..
}

# Function to deploy infrastructure only
deploy_infrastructure_only() {
    print_status "Deploying infrastructure only (without Ansible)..."
    deploy_integrated false
}

# Function to run Ansible manually
run_ansible_manual() {
    print_status "Running Ansible configuration manually..."
    
    cd ansible
    
    # Check if inventory file exists
    if [ ! -f "inventory/hosts" ]; then
        print_error "Ansible inventory file not found. Run infrastructure deployment first."
        exit 1
    fi
    
    # Test connectivity
    print_status "Testing connectivity to instances..."
    if ! ansible all -i inventory/hosts -m ping --ssh-common-args='-o StrictHostKeyChecking=no'; then
        print_error "Cannot connect to instances. Check your SSH configuration."
        exit 1
    fi
    
    # Run the playbook
    print_status "Running software installation playbook..."
    ansible-playbook -i inventory/hosts playbooks/install-software.yml -v --ssh-common-args='-o StrictHostKeyChecking=no'
    
    print_success "Ansible configuration completed!"
    
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
    echo "Deployment Summary:"
    terraform output -json deployment_summary | jq .
    
    echo ""
    print_success "Deployment information displayed!"
    print_status "You can SSH into your instances to verify installations."
    
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

# Function to validate and test deployment
validate_deployment() {
    print_status "Validating deployment..."
    
    cd terraform
    
    if [ ! -f "terraform.tfstate" ]; then
        print_error "No Terraform state found. Deploy infrastructure first."
        exit 1
    fi
    
    # Test SSH connectivity
    print_status "Testing SSH connectivity to all instances..."
    cd ../ansible
    
    if ansible all -i inventory/hosts -m ping --ssh-common-args='-o StrictHostKeyChecking=no' > /dev/null 2>&1; then
        print_success "All instances are reachable via SSH"
    else
        print_warning "Some instances may not be reachable"
    fi
    
    # Test Java and Python installations
    print_status "Verifying Java and Python installations..."
    if ansible all -i inventory/hosts -m shell -a 'java -version && python3 --version' --ssh-common-args='-o StrictHostKeyChecking=no' > /dev/null 2>&1; then
        print_success "Java and Python are installed on all instances"
    else
        print_warning "Java and/or Python may not be installed on some instances"
    fi
    
    cd ..
    print_success "Validation completed!"
}

# Main script logic
case "${1:-integrated}" in
    "integrated")
        print_status "Starting integrated deployment (Terraform + Ansible)..."
        check_prerequisites true
        deploy_integrated true
        show_deployment_info
        ;;
    "infrastructure")
        print_status "Deploying infrastructure only..."
        check_prerequisites false
        deploy_infrastructure_only
        show_deployment_info
        ;;
    "ansible")
        print_status "Running Ansible configuration only..."
        check_prerequisites true
        run_ansible_manual
        ;;
    "validate")
        print_status "Validating deployment..."
        check_prerequisites true
        validate_deployment
        ;;
    "destroy")
        destroy_infrastructure
        ;;
    "info")
        show_deployment_info
        ;;
    *)
        echo "Enhanced AWS Terraform Ansible Deployment Script"
        echo "Usage: $0 {integrated|infrastructure|ansible|validate|destroy|info}"
        echo ""
        echo "Commands:"
        echo "  integrated     - Full deployment with automatic Ansible execution (default)"
        echo "  infrastructure - Deploy infrastructure only (Terraform without Ansible)"
        echo "  ansible        - Run Ansible configuration on existing infrastructure"
        echo "  validate       - Validate deployment and test connectivity"
        echo "  destroy        - Destroy all resources"
        echo "  info           - Show deployment information"
        echo ""
        echo "Examples:"
        echo "  $0 integrated    # Deploy everything automatically"
        echo "  $0 infrastructure # Deploy EC2 instances only"
        echo "  $0 ansible       # Configure existing instances"
        exit 1
        ;;
esac
