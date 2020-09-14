# ELK instance
resource "aws_instance" "elk_instance" {
  ami                    = var.centos_ami
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = data.aws_subnet.elk_subnet.id
  vpc_security_group_ids = [aws_security_group.elk_instance.id]
  private_ip             = var.private_ip
  user_data              = data.template_file.user_data.rendered
  root_block_device {
    delete_on_termination = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags        = var.instance_tag
  volume_tags = var.instance_tag
}

# Elastic IP for VPN instance
resource "aws_eip" "elk_instance" {
  depends_on = [aws_instance.elk_instance]
  instance   = aws_instance.elk_instance.id
  vpc        = true
}

# DNS record for host layer
resource "aws_route53_record" "host" {
  depends_on = [aws_instance.elk_instance]
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = var.physical_record_name
  type       = "A"
  ttl        = "300"
  records    = [length(var.private_ip) > 0 ? aws_instance.elk_instance.private_ip : aws_eip.elk_instance.public_ip]
}

# DNS record for service layer
resource "aws_route53_record" "service" {
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
