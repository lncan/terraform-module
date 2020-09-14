# VPC
data "aws_vpc" "zone_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_tag_value]
  }
}

# Subnet of ipa instance
data "aws_subnet" "ipa_subnet" {
  filter {
    name    = "tag:Name"
    values  = [var.private_subnet_tag_value]
  }
}

# Public Zone
data "aws_route53_zone" "public_zone" {
  name = var.physical_domain_name
}

# Latest snapshot of volume of IPA instance
data "aws_ebs_snapshot" "ipa_volume" {
  most_recent = true
  filter {
    name      = "tag:Name"
    values    = [var.snapshot_tag_value]
  }
}

