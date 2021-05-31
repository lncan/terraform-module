# VPC
data "aws_vpc" "eks_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_name]
  }
}

data "aws_region" "current" {}

resource "random_string" "containerinsights-suffix" {
  length  = 5
  upper   = false
  lower   = true
  number  = false
  special = false
}

# locals {
#   suffix = var.petname && var.enabled ? random_string.containerinsights-suffix.0.result : ""
#   name   = join("-", compact([var.cluster_name, "container-insights", local.suffix]))
#   default-tags = merge(
#     { "terraform.io" = "managed" },
#     { "Name" = local.name },
#   )
# }
