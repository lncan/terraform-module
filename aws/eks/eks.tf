# Create EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.k8s_cluster_role.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    subnet_ids = data.aws_subnet_ids.eks_cluster_subnet.ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_security_group.eks_cluster_sg
  ]
}

# Create OIDC Privider
data "tls_certificate" "k8s_cluster_tls_certificate" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "k8s_cluster_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.k8s_cluster_tls_certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

locals {
  oidc = {
    arn = aws_iam_openid_connect_provider.k8s_cluster_oidc_provider.arn
    url = replace(aws_iam_openid_connect_provider.k8s_cluster_oidc_provider.url, "https://", "")
  }
}

# Create EKS Nodes 
resource "aws_launch_template" "eks_node" {
  name                    = var.node_launch_template_name
  image_id                = data.aws_ami.eks_node_image.image_id
  instance_type           = var.node_instance_type
  vpc_security_group_ids  = [aws_security_group.eks_node_sg.id]
  key_name                = var.ec2_ssh_key
  user_data               = base64encode(data.template_file.user_data.rendered)
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnet_ids.eks_node_subnet.ids

  launch_template {
    id      = aws_launch_template.eks_node.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_CloudWatchAgentServerPolicy,
    aws_iam_role_policy_attachment.eks_AmazonEKS_CNI_Policy,
    kubernetes_service_account.cni_service_account,
  ]
}
