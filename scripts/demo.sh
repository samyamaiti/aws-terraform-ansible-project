#!/bin/bash

# Demo script to show the project capabilities
# This script demonstrates the project without actually deploying to AWS

echo "🎯 AWS Terraform Ansible Project Demo"
echo "====================================="
echo ""

echo "📁 Project Structure:"
echo "--------------------"
tree -I '.terraform|.git' . || find . -type f -name "*.tf" -o -name "*.yml" -o -name "*.sh" | head -20

echo ""
echo "🔧 Terraform Configuration Preview:"
echo "-----------------------------------"
echo "Main Resources:"
grep -n "resource \"" terraform/main.tf | head -5

echo ""
echo "⚙️ Ansible Playbook Preview:"
echo "----------------------------"
echo "Tasks to be executed:"
grep -n "name:" ansible/playbooks/install-software.yml | head -5

echo ""
echo "🚀 Available Deployment Commands:"
echo "---------------------------------"
echo "1. Full integrated deployment:"
echo "   ./scripts/deploy-integrated.sh integrated"
echo ""
echo "2. Infrastructure only:"
echo "   ./scripts/deploy-integrated.sh infrastructure"
echo ""
echo "3. Ansible configuration only:"
echo "   ./scripts/deploy-integrated.sh ansible"
echo ""
echo "4. Validation:"
echo "   ./scripts/deploy-integrated.sh validate"
echo ""

echo "📊 What This Project Does:"
echo "-------------------------"
echo "✅ Provisions 10 EC2 instances in AWS"
echo "✅ Creates security groups with SSH/HTTP/HTTPS access"
echo "✅ Automatically installs Java 11 on all instances"
echo "✅ Automatically installs Python 3 + pip on all instances"
echo "✅ Configures development tools (git, vim, htop, etc.)"
echo "✅ Creates test files to verify installations"
echo "✅ Provides SSH connection commands"
echo "✅ Includes cleanup and validation tools"
echo ""

echo "🔐 Security Features:"
echo "--------------------"
echo "✅ SSH access restricted to your IP"
echo "✅ No hardcoded credentials"
echo "✅ AWS IAM integration"
echo "✅ Configurable security groups"
echo ""

echo "💰 Cost Estimate (t3.micro in us-west-2):"
echo "-----------------------------------------"
echo "• 10 x t3.micro instances: ~$8.50/month"
echo "• Data transfer: minimal"
echo "• Total estimated cost: <$10/month"
echo ""

echo "🎉 Demo Complete!"
echo "================"
echo "To deploy for real:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Create SSH key: aws ec2 create-key-pair --key-name my-terraform-key --query 'KeyMaterial' --output text > ~/.ssh/my-terraform-key.pem && chmod 400 ~/.ssh/my-terraform-key.pem"
echo "3. Run deployment: ./scripts/deploy-integrated.sh integrated"
echo ""
echo "🧹 To cleanup: ./scripts/deploy-integrated.sh destroy"
