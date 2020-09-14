# IPA security Group
resource "aws_security_group" "ipa_server" {
  name        = "Security group of IPA instance"
  vpc_id      = data.aws_vpc.zone_vpc.id
  description = "Security group of IPA instance"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.instance_tag
}

# SSH rules for instance
resource "aws_security_group_rule" "ipa_allow_ssh" {
  security_group_id = aws_security_group.ipa_server.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

# ICMP rule for instance
resource "aws_security_group_rule" "icmp_zone" {
  security_group_id = aws_security_group.ipa_server.id
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# TCP ingress rules for instance
resource "aws_security_group_rule" "ipa_server_tcp_ingress_trusted" {
  count             = length(local.tcp_ingress_ports)
  security_group_id = aws_security_group.ipa_server.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = local.tcp_ingress_ports[count.index]
  to_port           = local.tcp_ingress_ports[count.index]
}

# UDP ingress rules for instance
resource "aws_security_group_rule" "ipa_server_udp_ingress_trusted" {
  count             = length(local.udp_ingress_ports)
  security_group_id = aws_security_group.ipa_server.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = local.udp_ingress_ports[count.index]
  to_port           = local.udp_ingress_ports[count.index]
}

# Egress rules for ipa instance
resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipa_server.id
}
