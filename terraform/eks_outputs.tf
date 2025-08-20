output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(aws_eks_cluster.main[0].name, "Not deployed")
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = try(aws_eks_cluster.main[0].endpoint, "Not deployed")
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = var.eks_version
}

output "kubeconfig_update_command" {
  description = "Command to update kubeconfig for the EKS cluster"
  value       = var.deploy_eks ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main[0].name}" : "EKS cluster not deployed"
}
