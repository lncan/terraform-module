variable "ipa_admin_password" {
  type        = string
  description = "admin user kerberos password"
  default     = ""
}

variable "ipa_dm_password" {
  type        = string
  description = "Directory Manager password"
  default     = ""
}


variable "ipa_realm" {
  type        = string
  description = "The default REALM"
  default     = ""
}

variable "centos_ami" {
  type        = string
  description = "The default ami of centos 7 used for ipa instance"
  default     = "ami-07f65177cb990d65b"
}

variable "instance_tag" {
  type        = map(string)
  description = "Tag for ipa intance"
  default     = {}
}

variable "ipa_hostname" {
  type        = string
  description = "The host name of IPA instance"
  default     = ""
}

variable "ssh_key_name" {
  type        = string
  description = "The name of ssh key pair resource"
  default     = ""
}

variable "ipa_private_ip" {
  type        = string
  description = "The private IP of IPA instance"
  default     = ""
}

variable "path_to_ipa_install_script" {
  type        = string
  description = "The script for IPA initiation"
  default     = ""
}

variable "vpc_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of vpc"
  default     = ""
}

variable "private_subnet_tag_value" {
  type        = string
  description = "The value mapped to key that defined in vpc create session (in main.tf file) of private subnet"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "The type of ec2 instance"
  default     = ""
}

variable "volume_size" {
  type        = number
  description = "The size (GB) of volume of ec2 instance"
  default     = 8
}

variable "volume_type" {
  type        = string
  description = "The type of volume attached into instance"
  default     = ""
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

variable "elk_ipa_index" {
  type        = string
  description = "The name of index of IPA host"
  default     = ""
}


variable "volume_tag" {
  type        = map(string)
  description = "The tag for volume of instance"
  default     = {}
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






