variable vpc_name {
  type        = string
  default     = ""
  description = "The name of VPC"
}

variable eks_cluster_name {
  type        = string
  description = "The name of eks cluster"
  default     = ""
}

variable node_group_name {
  type        = string
  description = "The name of Node Group"
  default     = ""
}

variable node_desired_size {
  type        = number
  description = "The desired size of node group"
  default     = 1
}

variable node_min_size {
  type        = number
  description = "The min size of node group"
  default     = 1
}

variable node_max_size {
  type        = number
  description = "The max size of node group"
  default     = 1
}

variable ec2_ssh_key {
  type        = string
  description = "The name of ssh key for connection to nodes"
  default     = ""
}

variable disk_size {
  type        = number
  description = "The size of disk"
  default     = 20
}

variable node_instance_type {
  type        = string
  description = "The type of node instance"
  default     = ""
}

variable node_launch_template_name {
  type        = string
  description = "The name of the launch template of node instance"
  default     = ""
}

variable template_file_path {
  type        = string
  description = "The path of template files"
  default     = ""
}

variable manifest_folder_path {
  type        = string
  default     = ""
  description = "The path of K8s manifest folder"
}
