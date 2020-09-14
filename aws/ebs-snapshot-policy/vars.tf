variable "schedule_name" {
  type        = string
  description = "Name of schedule for taking snapshot in cycle"
  default     = ""
}

variable "interval" {
  type        = number
  description = "How often this lifecycle policy should be evaluated"
  default     = 1
}

variable "interval_unit" {
  type        = string
  description = "The unit for how often the lifecycle policy should be evaluated"
  default     = "HOURS"
}

variable "times" {
  type        = list(string)
  description = "The time when the lifecycle policy should be evaluated"
  default     = []
}

variable "number_of_snapshots_retained" {
  type        = number
  description = "How many snapshots to keep"
  default     = 1
}

variable "snapshot_tag" {
  type        = map(string)
  description = "The tag for snapshot will be created"
  default     = {}
}

variable "volume_target_tag" {
  type        = map(string)
  description = "The tag for determining target volume"
  default     = {}
}

variable "tag" {
  type        = map(string)
  description = "The tag for snapshot lifecycle policy"
  default     = {}
}

variable "role_name" {
  type        = string
  description = "Name for role"
  default     = ""
}

variable "policy_name" {
  type        = string
  description = "Name for policy"
  default     = ""
}






