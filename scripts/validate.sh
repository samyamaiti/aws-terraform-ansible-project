#!/bin/bash

# Validation script to verify the deployment
set -e

echo "🔍 Validating AWS Terraform Ansible Project Setup"
echo "=================================================="

# Check project structure
echo "✅ Checking project structure..."
required_files=(
    "terraform/main.tf"
    "terraform/variables.tf"
    "terraform/outputs.tf"
    "terraform/versions.tf"
    "ansible/playbooks/install-software.yml"
    "ansible/inventory/aws_ec2.yml"
    "ansible/ansible.cfg"
    "scripts/deploy.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ❌ $file missing"
        exit 1
    fi
done

# Check if terraform.tfvars exists
if [ -f "terraform/terraform.tfvars" ]; then
    echo "  ✓ terraform/terraform.tfvars configured"
else
    echo "  ⚠️  terraform/terraform.tfvars not found (copy from terraform.tfvars.example)"
fi

# Validate Terraform configuration
echo ""
echo "🔧 Validating Terraform configuration..."
cd terraform
if terraform validate; then
    echo "  ✅ Terraform configuration is valid"
else
    echo "  ❌ Terraform configuration has errors"
    exit 1
fi
cd ..

# Check Ansible syntax
echo ""
echo "🎭 Validating Ansible playbook..."
cd ansible
if ansible-playbook --syntax-check playbooks/install-software.yml; then
    echo "  ✅ Ansible playbook syntax is valid"
else
    echo "  ❌ Ansible playbook has syntax errors"
    exit 1
fi
cd ..

echo ""
echo "🎉 All validations passed! The project is ready for deployment."
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Copy and edit terraform.tfvars: cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
echo "3. Create SSH key pair: aws ec2 create-key-pair --key-name my-terraform-key --query 'KeyMaterial' --output text > ~/.ssh/my-terraform-key.pem && chmod 400 ~/.ssh/my-terraform-key.pem"
echo "4. Run deployment: ./scripts/deploy.sh"
