variable "billing_account" {
  description = "The billing account id that will be associated with the resources"
}

variable "org_id" {
  description = "The organization id that will be associated with the resources"
}

variable "project_unique_id" {
  description = "The unique id to be used for the project name"
}

variable "master_authorized_networks" {
  type = list(object({ cidr_block = string, display_name = string }))
  description = "The list of CIDR blocks which are allowed to access the master"
}

variable "project_name_prefix" {
  description = "The prefix to be used for the project name"
  default     = "poc-gke-gpu"
}

variable "region" {
  description = "The region in which the resources will be deployed"
  default     = "us-east1"
}

variable "subnet_private_access" {
  description = "Whether to enable private access for the subnet"
  default     = true
}

variable "subnet_flow_logs" {
  description = "Whether to enable flow logs for the subnet"
  default     = false
}

variable "subnet_flow_logs_sampling" {
  description = "The sampling rate for flow logs"
  default     = 0.5
}

variable "subnet_flow_logs_metadata" {
  description = "Whether to include metadata in flow logs"
  default     = "INCLUDE_ALL_METADATA"
}
