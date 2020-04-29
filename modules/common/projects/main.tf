locals {
  services = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}

resource "google_project" "cluster" {
  name                = var.name
  project_id          = var.name
  folder_id           = var.folder
  skip_delete         = true
  auto_create_network = false
  billing_account     = var.billing-account
}

resource "google_project_service" "enabled-apis" {
  for_each                   = toset(local.services)
  service                    = each.value
  project                    = google_project.cluster.project_id
  disable_dependent_services = true
}

output project {
  value = google_project.cluster
}
