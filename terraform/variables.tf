variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 10
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
  default     = "my-terraform-key"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-ansible-project"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

variable "run_ansible" {
  description = "Whether to run Ansible playbook after infrastructure provisioning"
  type        = bool
  default     = true
}

variable "wait_time_seconds" {
  description = "Time to wait for instances to be ready before running Ansible (in seconds)"
  type        = string
  default     = "120s"
}

# EKS Configuration
variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.27"
}

variable "eks_node_count" {
  description = "Number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "deploy_eks" {
  description = "Whether to deploy EKS cluster"
  type        = bool
  default     = true
}
