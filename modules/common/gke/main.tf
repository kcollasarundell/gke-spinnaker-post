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

resource "google_compute_subnetwork_iam_member" "compute" {
  for_each   = google_compute_subnetwork.subnets
  project    = each.value.project
  region     = each.value.region
  subnetwork = each.value.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.project.number}@cloudservices.gserviceaccount.com"
}
resource "google_compute_subnetwork_iam_member" "container" {
  for_each   = google_compute_subnetwork.subnets
  project    = each.value.project
  region     = each.value.region
  subnetwork = each.value.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "xpn" {
  role    = "roles/container.hostServiceAgentUser"
  project = var.host-project
  member  = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_service_account" "service_account" {
  account_id   = "${var.name}-compute"
  display_name = "Compute service account for cluster"
  project      = var.project_id
}



resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = var.name
  project  = var.project_id
  location = var.location
  # node_locations    = var.location

  network = "projects/${var.project_id}/global/networks/${var.network}"

  network_policy {
    enabled = false
  }
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
  }
  
  release_channel { channel = "RAPID" }

  subnetwork                = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.name}"
  default_max_pods_per_node = 100

  enable_shielded_nodes = true

  vertical_pod_autoscaling {
    enabled = true
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = true
    }
    dns_cache_config {
      enabled = true
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range[1].range_name

  }
  remove_default_node_pool = true
  initial_node_count       = 1
  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }
  lifecycle {
    ignore_changes = [node_pool, initial_node_count]
  }
}
resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  workload_metadata_config {
    node_metadata = GKE_METADATA_SERVER
  }
  node_config {
    preemptible  = true
    machine_type = var.node_size

    metadata = {
      disable-legacy-endpoints = "true"
    }

    disk_size_gb    = 10
    disk_type       = "pd-ssd"
    service_account = google_service_account.service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


resource "google_project_iam_member" "cluster_service_account-gcr" {
  project = var.registry_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

data "google_client_config" "default" {
}
