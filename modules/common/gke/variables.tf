variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "host-project" {
  type = string
}
variable "host-network-name" {
  type = string
}

variable "clusters" {
  type = map(object({
    region   = string
    ip_range = string
  }))
}
