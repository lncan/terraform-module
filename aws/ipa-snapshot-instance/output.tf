# Print the domain name of IPA instance
output "ipa_physical_domain_name" {
  value = aws_route53_record.service.name
}

# Print the private ip of IPA instance
output "ipa_private_ip" {
  value = aws_instance.ipa_instance.private_ip
}