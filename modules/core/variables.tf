variable "name" {
  type = string
}

variable "base-folder" {
  type = string
}

variable "billing-account" {
  type = string
}

variable "core-clusters" {
  type = map(object({
    region   = string
    ip_range = string
    node_size = string
    control_network = string
  }))
}

variable "prod-clusters" {
  type = map(object({
    region   = string
    ip_range = string
    node_size = string
    control_network = string
  }))
}

variable "staging-clusters" {
  type = map(object({
    region   = string
    ip_range = string
    node_size = string
    control_network = string
  }))
}
