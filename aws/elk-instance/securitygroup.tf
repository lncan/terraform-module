# elk security Group
resource "aws_security_group" "elk_instance" {
  name        = "Security group of elk instance"
  vpc_id      = data.aws_vpc.zone_vpc.id
  description = "Security group of elk instance"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.instance_tag
}

# SSH rules for instance
resource "aws_security_group_rule" "elk_allow_ssh" {
  security_group_id = aws_security_group.elk_instance.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

# ICMP rule for instance
resource "aws_security_group_rule" "icmp" {
  security_group_id = aws_security_group.elk_instance.id
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# TCP ingress rules for instance
resource "aws_security_group_rule" "elk_instance_tcp_ingress_trusted" {
  count             = length(var.tcp_ingress_ports)
  security_group_id = aws_security_group.elk_instance.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = var.tcp_ingress_ports[count.index]
  to_port           = var.tcp_ingress_ports[count.index]
}

# UDP ingress rules for instance
resource "aws_security_group_rule" "elk_instance_udp_ingress_trusted" {
  count             = length(var.udp_ingress_ports)
  security_group_id = aws_security_group.elk_instance.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = var.udp_ingress_ports[count.index]
  to_port           = var.udp_ingress_ports[count.index]
}

# Egress rules for elk instance
resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elk_instance.id
}
