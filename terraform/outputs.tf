output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.ec2_instances[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.ec2_instances[*].private_ip
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.ec2_instances[*].id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for i, instance in aws_instance.ec2_instances : 
    "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.public_ip}"
  ]
}

output "ansible_inventory_file" {
  description = "Path to generated Ansible inventory file"
  value       = "${path.module}/../ansible/inventory/hosts"
}

output "ansible_execution_enabled" {
  description = "Whether Ansible execution was enabled"
  value       = var.run_ansible
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    instances_created = length(aws_instance.ec2_instances)
    ansible_enabled   = var.run_ansible
    wait_time         = var.wait_time_seconds
    eks_enabled       = var.deploy_eks
    eks_cluster_name  = try(var.deploy_eks ? aws_eks_cluster.main[0].name : "Not deployed", "Not deployed")
    eks_endpoint      = try(var.deploy_eks ? aws_eks_cluster.main[0].endpoint : "Not deployed", "Not deployed")
    timestamp         = timestamp()
  }
}


