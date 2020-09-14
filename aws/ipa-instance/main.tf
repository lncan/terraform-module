# Local values
locals {
  # The TCP ports that the IPA servers should listen on
  tcp_ingress_ports = [
    80,  # HTTP
    88,  # kinit
    443, # HTTPS
    464, # kpasswd
    389, # LDAP
    636, # LDAPS
    53
  ]

  # The UDP ports that the IPA servers should listen on
  udp_ingress_ports = [
    88,  # kinit
    464, # kpasswd
    53,
    123
  ]
}

# IPA instance
resource "aws_instance" "ipa_instance" {
  ami                    = var.centos_ami
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = data.aws_subnet.ipa_subnet.id
  private_ip             = var.ipa_private_ip
  vpc_security_group_ids = [aws_security_group.ipa_server.id]
  user_data              = data.template_file.user_data.rendered
  root_block_device {
    delete_on_termination = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
  }
  tags        = var.instance_tag
  volume_tags = var.volume_tag
}

# DNS record for host layer
resource "aws_route53_record" "host" {
  depends_on = [aws_instance.ipa_instance]
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = var.physical_record_name
  type       = "A"
  ttl        = "300"
  records    = [var.ipa_private_ip]
}
