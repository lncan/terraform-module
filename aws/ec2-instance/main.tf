resource "aws_instance" "instance" {
  count = var.instance_count

  ami                    = var.ami
  instance_type          = var.instance_type
  user_data              = data.template_file.user_data.rendered
  subnet_id              = data.aws_subnet.instance_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  private_ip             = var.private_ip

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check

  tags = var.instance_tags

  volume_tags = var.volume_tags
}

resource "aws_eip" "instance" {
  count      = var.public_instance ? 1 : 0
  depends_on = [aws_instance.instance]
  instance   = aws_instance.instance.id
  vpc        = true
}

resource "aws_route53_record" "instance" {
  depends_on = [aws_instance.instance]
  count      = length(var.physical_domain_name) > 0 ? 1 : 0
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = var.physical_record_name
  type       = "A"
  ttl        = "300"
  records    = length(aws_eip.instance.public_ip) > 0 ? aws_eip.instance.public_ip : var.private_ip
}

resource "aws_route53_record" "alias" {
  count      = var.physical_domain_name && length(var.alias) > 0 && length(var.alias["name"]) > 0 ? length(var.alias["name"]) : 0
  zone_id    = data.aws_route53_zone.public_zone.zone_id
  name       = element(var.alias["name"], count.index)
  type       = "CNAME"
  alias {
    name     = aws_route53_record.instance.fqdn
    zone_id  = data.aws_route53_record.public_zone.zone_id
    evaluate_target_health = true
  }
}