# VPC
data "aws_vpc" "eks_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_name]
  }
}

# subnet IDs
data "aws_subnet_ids" "eks_cluster_subnet" {
  vpc_id = data.aws_vpc.eks_vpc.id
}

# Private subnet ID
data "aws_subnet_ids" "eks_node_subnet" {
  vpc_id = data.aws_vpc.eks_vpc.id
  tags = {
    Tier = "Private"
  }
}

# Current region
data "aws_region" "current_region" {}

# Node image
data "aws_ami" "eks_node_image" {
  most_recent      = true
  owners           = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks_cluster.version}-v*"]
  }
}

# EKS cluster
data "aws_eks_cluster_auth" "eks_cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

# EKS node user-data
data "template_file" "user_data" {
  template = file(var.template_file_path)
  vars = {
    cluster_auth_base64 = aws_eks_cluster.eks_cluster.certificate_authority.0.data
    endpoint            = aws_eks_cluster.eks_cluster.endpoint
    cluster_name        = aws_eks_cluster.eks_cluster.name
  }
}
