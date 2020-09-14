variable "centos_ami" {
  type        = string
  description = "The default ami of centos 7 used for docker instance"
  default     = "ami-07f65177cb990d65b"
}

variable "instance_tag" {
  type        = map(string)
  description = "Tag for docker intance"
  default     = {}
}

variable "ssh_key_name" {
  type        = string
  description = "The name of ssh key pair resource"
  default     = ""
}

variable "path_to_docker_install_script" {
  type        = string
  description = "The script for docker initiation"
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

variable "physical_domain_name" {
  type        = string
  description = "The name of public zone"
  default     = ""
}

variable "elk_password" {
  type        = string
  description = "The password of elastic user of elasticsearch"
  default     = ""
}

variable "elk_address" {
  type        = string
  description = "The address of ELK stack"
  default     = ""
}

variable "elk_docker_index" {
  type        = string
  description = "The index name of docker instance on ELK"
  default     = ""
}

variable "private_ip" {
  type        = string
  description = "The private IP of docker instance"
  default     = ""
}

variable "ingress_ports" {
  type        = list(number)
  description = "(optional) describe your variable"
  default     = []
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







