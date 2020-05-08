provider "google" {
  version = "~> 3.16.0"
}
provider "google-beta" {
  version = "~> 3.17.0"
}

data "google_billing_account" "bills" {
  billing_account = var.billing
  open            = true
}

module compute {
  source          = "./modules/core"
  name            = var.prefix
  billing-account = data.google_billing_account.bills.id
  base-folder     = var.base_folder
  core-clusters = {
    sydney = {
      region   = "australia-southeast1"
      ip_range = "172.16.0.0/16"
      node_size = "e2-medium"
      control_network = "10.0.0.0/28"
  } }
  staging-clusters = {
    sydney = {
      region   = "australia-southeast1"
      ip_range = "172.17.0.0/16"
      node_size = "e2-medium"
      control_network = "10.0.0.16/28"
    }
  }
  prod-clusters = {
    central = {
      region   = "us-central1"
      ip_range = "172.18.0.0/16"
      node_size = "e2-medium"
      control_network = "10.0.0.32/28"
    }
    sydney = {
      region   = "australia-southeast1"
      ip_range = "172.19.0.0/16"
      node_size = "e2-medium"
      control_network = "10.0.0.48/28"
    }
  }
}


output "core_kubernetes_endpoint" {
  value = module.compute.core_kubernetes_endpoint
}
output "prod_kubernetes_endpoint" {
  value = module.compute.prod_kubernetes_endpoint
}
output "staging_kubernetes_endpoint" {
  value = module.compute.staging_kubernetes_endpoint
}