variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
  default     = ""
}

variable "public_cidr_block" {
  type        = list(string)
  description = "CIDR block for public subnet"
  default     = []
}

variable "private_cidr_block" {
  type        = list(string)
  description = "CIDR block for private subnet"
  default     = []
}

variable "vpc_tag" {
  type        = map(string)
  description = "Tag for VPC"
  default     = {}
}

variable "public_subnet_tag" {
  type        = list(map(string))
  description = "Tag for public subnet"
  default     = []
}

variable "private_subnet_tag" {
  type        = list(map(string))
  description = "Tag for private subnet"
  default     = []
}

variable "internet_gateway_tag" {
  type        = map(string)
  description = "Tag for internet gateway"
  default     = {}
}

variable "nat_gateway_tag" {
  type        = map(string)
  description = "Tag for nat gateway"
  default     = {}
}

variable "public_rtb_tag" {
  type        = map(string)
  description = "Tag for public route table"
  default     = {}
}

variable "private_rtb_tag" {
  type        = list(map(string))
  description = "Tag for private route table"
  default     = []
}

variable "create_vpc" {
  type        = bool
  description = "Controls if VPC should be created (it affects almost all resources)"
  default     = true
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = false
}

variable "single_nat_gateway" {
  type        = bool
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = true
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones for subnets"
  default     = []
}