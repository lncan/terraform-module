output "eks_name" {
  description = "The name of EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "oidc" {
  description = "The OIDC provider attributes for IAM Role for ServiceAccount"
  value = zipmap(
    ["url", "arn"],
    [local.oidc["url"], local.oidc["arn"]]
  )
}

output "helmconfig" {
  description = "The configurations map for Helm provider"
  sensitive   = true
  value = {
    host  = aws_eks_cluster.eks_cluster.endpoint
    token = data.aws_eks_cluster_auth.eks_cluster.token
    ca    = aws_eks_cluster.eks_cluster.certificate_authority.0.data
  }
}