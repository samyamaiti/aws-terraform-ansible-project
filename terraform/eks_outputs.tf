locals {
  eks_cluster_name = try(aws_eks_cluster.main[0].name, "")
  eks_cluster_endpoint = try(aws_eks_cluster.main[0].endpoint, "")
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.deploy_eks ? local.eks_cluster_name : "Not deployed"
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = var.deploy_eks ? local.eks_cluster_endpoint : "Not deployed"
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = var.deploy_eks ? var.eks_version : "Not deployed"
}

output "kubeconfig_update_command" {
  description = "Command to update kubeconfig for the EKS cluster"
  value       = var.deploy_eks && local.eks_cluster_name != "" ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.eks_cluster_name}" : "EKS cluster not deployed"
}
