locals {
  config = {
    cluster_name     = var.deploy_eks ? try(aws_eks_cluster.main[0].name, "") : ""
    cluster_endpoint = var.deploy_eks ? try(aws_eks_cluster.main[0].endpoint, "") : ""
  }
  eks_deployed = var.deploy_eks && local.config.cluster_name != ""
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.eks_deployed ? local.config.cluster_name : "Not deployed"
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = local.eks_deployed ? local.config.cluster_endpoint : "Not deployed"
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = local.eks_deployed ? var.eks_version : "Not deployed"
}

output "kubeconfig_update_command" {
  description = "Command to update kubeconfig for the EKS cluster"
  value       = local.eks_deployed ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.config.cluster_name}" : "EKS cluster not deployed"
}
