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

variable "snapshot_tag_value" {
  type        = string
  description = "The value of tag of snapshot"
  default     = ""
}

variable "volume_type" {
  type        = string
  description = "The type of volume attached into instance"
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






