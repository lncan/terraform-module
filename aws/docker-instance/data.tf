# VPC
data "aws_vpc" "zone_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_tag_value]
  }
}

# Subnet of docker instance
data "aws_subnet" "docker_subnet" {
  filter {
    name    = "tag:Name"
    values  = [var.private_subnet_tag_value]
  }
}

# User data
data "template_file" "user_data" {
  template = file(var.path_to_docker_install_script)
  vars = {
    elk_password      = var.elk_password
    elk_address       = var.elk_address
    elk_docker_index  = var.elk_docker_index
  }
}

# Public Zone
data "aws_route53_zone" "public_zone" {
  name = var.physical_domain_name
}

