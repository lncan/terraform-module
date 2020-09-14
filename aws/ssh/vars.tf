variable "ssh_key_name" {
  type        = string
  description = "the name of ssh connection"
  default     = ""
}

variable "path_to_public_key" {
  type        = string
  description = "The ssh public key for connecting to instances"
  default     = ""
}