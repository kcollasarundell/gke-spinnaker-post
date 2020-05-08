resource "google_folder" "base_folder" {
  display_name = var.name
  parent       = var.base-folder
}

resource "google_folder" "core_folder" {
  display_name = "control-plane"
  parent       = google_folder.base_folder.name
}

resource "google_folder" "worker_folder" {
  display_name = "worker-clusters"
  parent       = google_folder.base_folder.name
}

resource "google_folder" "worker_tiers" {
  for_each     = toset(["production", "staging"])
  display_name = each.key
  parent       = google_folder.worker_folder.name
}

module "core-project" {
  source          = "../common/projects"
  name            = "${var.name}-core"
  folder          = google_folder.core_folder.name
  billing-account = var.billing-account
}

module "prod-project" {
  source          = "../common/projects"
  name            = "${var.name}-prod"
  folder          = google_folder.worker_tiers["production"].name
  billing-account = var.billing-account
}

module "staging-project" {
  source          = "../common/projects"
  name            = "${var.name}-staging"
  folder          = google_folder.worker_tiers["staging"].name
  billing-account = var.billing-account
}

module "host-project" {
  source          = "../common/projects"
  name            = "${var.name}-host-net"
  folder          = google_folder.core_folder.name
  billing-account = var.billing-account
}

resource "google_compute_network" "host-vpc" {
  name                    = var.name
  project                 = module.host-project.project.project_id
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_shared_vpc_host_project" "host-vpc" {
  project = module.host-project.project.project_id
}

module "core-clusters" {
  source            = "../common/gke"
  name              = "${var.name}-core"
  clusters          = var.core-clusters
  project           = module.core-project.project.project_id
  host-project      = module.host-project.project.project_id
  host-network-name = google_compute_network.host-vpc.name
}

module "prod-clusters" {
  source            = "../common/gke"
  name              = "${var.name}-prod"
  clusters          = var.prod-clusters
  project           = module.prod-project.project.project_id
  host-project      = module.host-project.project.project_id
  host-network-name = google_compute_network.host-vpc.name
}

module "staging-clusters" {
  source            = "../common/gke"
  name              = "${var.name}-staging"
  clusters          = var.staging-clusters
  project           = module.staging-project.project.project_id
  host-project      = module.host-project.project.project_id
  host-network-name = google_compute_network.host-vpc.name
}


output "core_kubernetes_endpoint" {
  value = module.core-clusters.kubernetes_endpoint
}
output "prod_kubernetes_endpoint" {
  value = module.prod-clusters.kubernetes_endpoint
}
output "staging_kubernetes_endpoint" {
  value = module.staging-clusters.kubernetes_endpoint
}
