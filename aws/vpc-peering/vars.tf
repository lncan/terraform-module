variable "zone0_prefix" {
  type        = string
  description = "The prefix of zone0's vpc for naming"
  default     = ""
}

variable "zone1_prefix" {
  type        = string
  description = "The prefix of zone1's vpc for naming"
  default     = ""
}

variable "auto_accept_peering" {
  description = "Auto accept peering connection: bool"
  default     = true
}

variable "peering_tag" {
  type        = string
  description = "The tag value of peering resource"
  default     = ""
}

variable "dns_resolution" {
  description = "Indicates whether a local VPC can resolve public DNS hostnames to private IP addresses when queried from instances in a peer VPC"
  default     = true
}
