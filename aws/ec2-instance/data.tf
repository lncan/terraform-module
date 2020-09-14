# VPC
data "aws_vpc" "zone_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_tag_value]
  }
}

# Subnet of elk instance
data "aws_subnet" "instance_subnet" {
  filter {
    name    = "tag:Name"
    values  = [var.instance_subnet_tag]
  }
}

# User data
data "template_file" "user_data" {
  template  = file(var.path_to_script)
  vars      = var.user_data_variable
}

# Public Zone
data "aws_route53_zone" "public_zone" {
  count = length(var.physical_domain_name) > 0 ? 1 : 0
  name  = var.physical_domain_name
}