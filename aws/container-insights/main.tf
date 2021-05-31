## kubernetes container-insights
resource "helm_release" "containerinsights" {
  name             = "eks-cw"
  chart            = "/Users/lncan/Learn/infras/terraform-module/aws/container-insights/charts/container-insights"
  namespace        = "amazon-cloudwatch"
  create_namespace = true
  cleanup_on_fail  = true

  values     = [<<EOF
  cluster:
    name: ${var.cluster_name}
    region: ${data.aws_region.current.name}
  serviceAccount:
    name: aws-container-insights
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.container_insight_role.arn}
  EOF
  ]
}
