# Security group for ingress instance
resource "aws_security_group" "instance" {
  name        = "Security group of instance"
  vpc_id      = data.aws_vpc.zone_vpc.id
  description = "Security group of instance"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.instance_tag
}

# SSH rules for ingress instance
resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

# ICMP rules for ingress instance
resource "aws_security_group_rule" "icmp" {
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

# Egress rules for ingress instance
resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

# TCP ingress rules for IPA
resource "aws_security_group_rule" "ipa_server_tcp_ingress_trusted" {
  count             = length(local.tcp_ingress_ports)
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = local.tcp_ingress_ports[count.index]
  to_port           = local.tcp_ingress_ports[count.index]
}

# UDP ingress rules for IPA
resource "aws_security_group_rule" "ipa_server_udp_ingress_trusted" {
  count             = length(local.udp_ingress_ports)
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = local.udp_ingress_ports[count.index]
  to_port           = local.udp_ingress_ports[count.index]
}

