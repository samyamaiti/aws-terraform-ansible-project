# Get current IP for security group
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-security-group"
    Project = var.project_name
  }
}

# EC2 Instances
resource "aws_instance" "ec2_instances" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = data.aws_subnets.default.ids[count.index % length(data.aws_subnets.default.ids)]

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 python3-pip
              # Install AWS CLI for Ansible dynamic inventory
              pip3 install awscli boto3 botocore
              EOF

  tags = {
    Name        = "${var.project_name}-instance-${count.index + 1}"
    Project     = var.project_name
    Environment = "development"
    AnsibleManaged = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create local inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory/hosts.tpl", {
    instances = aws_instance.ec2_instances[*]
  })
  filename = "${path.module}/../ansible/inventory/hosts"

  depends_on = [aws_instance.ec2_instances]
}

# Wait for instances to be ready before running Ansible
resource "time_sleep" "wait_for_instances" {
  count = var.run_ansible ? 1 : 0
  depends_on = [aws_instance.ec2_instances]
  create_duration = var.wait_time_seconds
}

# Run Ansible playbook to configure EC2 instances
resource "null_resource" "configure_instances" {
  count = var.run_ansible ? 1 : 0

  # Run Ansible playbook to install software on EC2 instances
  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i inventory/hosts.tpl playbooks/install-software.yml"
    
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  depends_on = [aws_instance.ec2_instances, time_sleep.wait_for_instances]
}

# Deploy microservice to EKS cluster (conditional)
resource "null_resource" "deploy_microservice" {
  count = var.deploy_eks ? 1 : 0

  # Run Ansible playbook to deploy microservice to EKS
  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook playbooks/deploy-microservice.yml -e eks_cluster_name=${module.eks[0].cluster_name} -e aws_region=${var.aws_region}"
    
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  depends_on = [module.eks]
}
