# Print public ip of vpn instance
output "vpn_public_ip" {
  value = aws_eip.vpn_instance.public_ip
}
