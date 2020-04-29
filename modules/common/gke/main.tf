data "google_compute_network" "host-vpc" {
  name    = var.host-network-name
  project = var.host-project
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_compute_subnetwork" "subnets" {
  for_each      = var.clusters
  name          = "${var.name}-${each.key}"
  ip_cidr_range = cidrsubnet(cidrsubnet(each.value.ip_range, 1, 1), 1, 0)
  project       = var.host-project
  region        = each.value.region
  network       = data.google_compute_network.host-vpc.self_link

  private_ip_google_access = true
  secondary_ip_range = [
    {
      range_name    = "${each.key}-pods"
      ip_cidr_range = cidrsubnet(each.value.ip_range, 1, 0)
    },
    {
      range_name    = "${each.key}-services"
      ip_cidr_range = cidrsubnet(cidrsubnet(each.value.ip_range, 1, 1), 1, 1)
    }
  ]
}

resource "google_compute_shared_vpc_service_project" "clusters" {
  host_project    = var.host-project
  service_project = var.project
}

resource "google_compute_subnetwork_iam_binding" "binding" {
  for_each   = google_compute_subnetwork.subnets
  project    = each.value.project
  region     = each.value.region
  subnetwork = each.value.name
  role       = "roles/compute.networkUser"
  members = [
    "serviceAccount:${data.google_project.project.number}@cloudservices.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  ]
}
