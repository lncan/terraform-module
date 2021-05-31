provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.eks_cluster.token
  }
}

# Ingress Controller Deployment
resource "helm_release" "alb_ingress" {
  depends_on = [
    # kubernetes_cluster_role_binding.alb_ingress_controller,
    aws_eks_node_group.eks_node_group,
  ]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values     = [<<EOF
  clusterName : dev_k8s_cluster
  region: us-east-1
  vpcId: ${data.aws_vpc.eks_vpc.id}
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.alb_ingress_role.arn}
  EOF
  ]
}

# Pod Service Account
resource "kubernetes_service_account" "cni_service_account" {
  metadata {
    name = "aws-node"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cni_service_account_role.arn
    }
  }
  automount_service_account_token = true
}