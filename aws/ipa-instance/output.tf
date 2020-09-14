# Print the domain name of IPA instance
output "ipa_physical_domain_name" {
  value = aws_route53_record.host.fqdn
}