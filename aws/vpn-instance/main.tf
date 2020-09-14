# Local values
locals {
  # The TCP ports that the ingress instance should listen to forward to local network
  tcp_ingress_ports = [
    80,  # HTTP
    88,  # kinit
    443, # HTTPS
    464, # kpasswd
    389, # LDAP
    636, # LDAPS
    53
  ]
  # The UDP ports that the ingress instance should listen to forward to local network
  udp_ingress_ports = [
    88,  # kinit
    464, # kpasswd
    53,
    123,
    500,
    4500
  ]
}

# VPN instance
resource "aws_instance" "vpn_instance" {
  ami                    = var.centos_ami
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = data.aws_subnet.instance_subnet.id
  vpc_security_group_ids = [aws_security_group.vpn_instance.id]
  source_dest_check      = false
  user_data              = data.template_file.user_data.rendered
  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }
  tags        = var.instance_tag
  volume_tags = var.instance_tag
}

# Create route rule between local network and aws
resource "aws_route" "access_local" {
  depends_on             = [aws_instance.vpn_instance]
  route_table_id         = data.aws_route_table.private_rtb.route_table_id
  destination_cidr_block = var.office_network
  instance_id            = aws_instance.vpn_instance.id
}

# Elastic IP for VPN instance
resource "aws_eip" "vpn_instance" {
  depends_on = [aws_instance.vpn_instance]
  instance   = aws_instance.vpn_instance.id
  vpc        = true
}

# DNS record for host layer
resource "aws_route53_record" "host" {
  depends_on = [aws_eip.vpn_instance]
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = var.physical_record_name
  type       = "A"
  ttl        = "300"
  records    = [aws_eip.vpn_instance.public_ip]
}

# DNS record for service layer
resource "aws_route53_record" "services" {
  depends_on = [aws_route53_record.host]
  count      = length(var.services_record_name)
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = element(var.services_record_name, count.index)
  type       = "A"
  alias {
    name                   = aws_route53_record.host.fqdn
    zone_id                = data.aws_route53_zone.public_zone.zone_id
    evaluate_target_health = true
  }
}



