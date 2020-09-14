variable "centos_ami" {
  type        = string
  description = "The default ami of Centos 7"
  default     = "ami-07f65177cb990d65b"
}

variable "ssh_key_name" {
  type        = string
  description = "The name of ssh key resource"
  default     = ""
}

variable "instance_tag" {
  type        = map(string)
  description = "The tag value of vpn instance"
  default     = {}
}

variable "path_to_vpn_install_script" {
  type        = string
  description = "The path of vpn installation script"
  default     = ""
}

variable "office_network" {
  type        = string
  description = "The network of headquaters"
  default     = ""
}

variable "vpc_network" {
  type        = string
  description = "The network of VPC"
  default     = ""
}

variable "ad_admin_username" {
  type        = string
  description = "the username of administrator of LDAP Server"
  default     = ""
}

variable "ad_admin_password" {
  type        = string
  description = "the password of administrator of LDAP Server"
  default     = ""
}

variable "ad_primary_domain" {
  type        = string
  description = "The primary DNS domain of IPA deployment"
}

variable "ad_ip_address" {
  type        = string
  description = "The IP address of IPA server"
  default     = ""
}

variable "ad_domain_name" {
  type        = string
  description = "The domain name of ipa server"
  default     = ""
}

variable "client_server_psk" {
  type        = string
  description = "Preshared-Keys for connection between Users and VPN server"
  default     = ""
}

variable "site_to_site_psk" {
  type        = string
  description = "Preshared-Keys for connection between local network and VPN on AWS"
  default     = ""
}

variable "office_public_ip" {
  type        = string
  description = "The public IP of office network"
  default     = ""
}

variable "vpn_client_ip_pool" {
  type        = string
  description = "The range of IP for client connecting to VPN server"
  default     = ""
}

variable "vpn_dns_server" {
  type        = string
  description = "The DNS server in VPN"
  default     = ""
}

variable "public_subnet_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of public subnet"
  default     = ""
}

variable "private_subnet_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of private subnet"
  default     = ""
}

variable "private_route_table_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of private route table"
  default     = ""
}

variable "vpc_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of vpc"
  default     = ""
}

variable "volume_size" {
  type        = number
  description = "The size (GB) of volume of ec2 instance"
  default     = 8
}

variable "instance_type" {
  type        = string
  description = "The type of instance"
  default     = ""
}

variable "volume_type" {
  type        = string
  description = "The type of volume attached into instance"
  default     = ""
}

variable "vpn_hostname" {
  type        = string
  description = "The hostname of VPN instance"
  default     = ""
}

variable "physical_domain_name" {
  type        = string
  description = "The name of public zone"
  default     = ""
}

variable "physical_record_name" {
  type        = string
  description = "The record name of host"
  default     = ""
}

variable "services_record_name" {
  type        = list(string)
  description = "The record names of services"
  default     = []
}

variable "elk_address" {
  type        = string
  description = "The address of ELK instance"
  default     = ""
}

variable "elk_password" {
  type        = string
  description = "The password of ELK instance"
  default     = ""
}

variable "elk_vpn_index" {
  type        = string
  description = "The name of index of VPN host"
  default     = ""
}








