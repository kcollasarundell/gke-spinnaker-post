variable "name" {
  description = "The name of the cluster"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "project" {
    description = "the project to run the cluster in"
}

variable "network" {
  description = "The VPC network to host the cluster in"
}

variable "node_size" {
  description = "Node type for the cluster"
}

variable "ip_ranges" {
  description = "The ip range to use for cluster/pods/nodes"
}

variable "compute_engine_service_account" {
  description = "Service account to associate to the nodes in the cluster"
}

