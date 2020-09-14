# VPC
data "aws_vpc" "zone_vpc" {
  filter {
    name    = "tag:Name"
    values  = [var.vpc_tag_value]
  }
}

# VPN subnet
data "aws_subnet" "instance_subnet" {
  vpc_id    = data.aws_vpc.zone_vpc.id
  filter {
    name    = "tag:Name"
    values  = [var.public_subnet_tag_value]
  }
}

# Private route table
data "aws_route_table" "private_rtb" {
  vpc_id    = data.aws_vpc.zone_vpc.id
  filter {
    name    = "tag:Name"
    values  = [var.private_route_table_tag_value]
  }
}

# Services subnet
data "aws_subnet" "services_subnet" {
  vpc_id    = data.aws_vpc.zone_vpc.id
  filter {
    name    = "tag:Name"
    values  = [var.private_subnet_tag_value]
  }
}

# Public Zone
data "aws_route53_zone" "public_zone" {
  name      = var.physical_domain_name
}

# User data
data "template_file" "user_data" {
  template = file(var.path_to_vpn_install_script)
  vars = {
    ad_ip_address       = var.ad_ip_address
    ad_domain_name      = var.ad_domain_name
    ad_primary_domain   = var.ad_primary_domain
    ad_admin_username   = var.ad_admin_username
    ad_admin_password   = var.ad_admin_password
    client_server_psk   = var.client_server_psk
    office_public_ip    = var.office_public_ip
    office_network      = var.office_network
    vpc_network         = var.vpc_network
    vpn_client_ip_pool  = var.vpn_client_ip_pool
    vpn_dns_server      = var.vpn_dns_server
    site_to_site_psk    = var.site_to_site_psk
    vpn_hostname        = var.vpn_hostname
    elk_address         = var.elk_address
    elk_password        = var.elk_password
    elk_vpn_index       = var.elk_vpn_index
  }
}