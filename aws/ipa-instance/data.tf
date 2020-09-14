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

# User data
data "template_file" "user_data" {
  template = file(var.path_to_ipa_install_script)
  vars = {
    ipa_hostname        = var.ipa_hostname
    ipa_ip              = var.ipa_private_ip
    ipa_admin_password  = var.ipa_admin_password
    ipa_dm_password     = var.ipa_dm_password
    ipa_realm           = var.ipa_realm
    elk_address         = var.elk_address
    elk_password        = var.elk_password
    elk_ipa_index       = var.elk_ipa_index
  }
}


