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

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Create Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-${count.index + 1}"
    Project = var.project_name
  }
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project_name}-private-subnet-${count.index + 1}"
    Project = var.project_name
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = var.project_name
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = aws_vpc.main.id

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
  subnet_id              = aws_subnet.public[count.index % length(var.public_subnet_cidrs)].id

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 python3-pip
              # Install AWS CLI for Ansible dynamic inventory
              pip3 install awscli boto3 botocore
              EOF

  tags = {
    Name           = "${var.project_name}-instance-${count.index + 1}"
    Project        = var.project_name
    Environment    = "development"
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
  count           = var.run_ansible ? 1 : 0
  depends_on      = [aws_instance.ec2_instances]
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
    command = "cd ../ansible && ansible-playbook playbooks/deploy-microservice.yml -e eks_cluster_name=${aws_eks_cluster.main[0].name} -e aws_region=${var.aws_region}"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      AWS_REGION                = var.aws_region
    }
  }

  triggers = {
    cluster_endpoint = aws_eks_cluster.main[0].endpoint
    cluster_name     = aws_eks_cluster.main[0].name
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}
