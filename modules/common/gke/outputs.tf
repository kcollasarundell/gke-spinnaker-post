output "kubernetes_endpoint" {
  sensitive = true
  value = {
    for key in local.clusterkeys :
    key => google_container_cluster.clusters[key].endpoint
  }
}

locals {
  clusterkeys = keys(var.clusters)

}

output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}
output "ca_certificate" {
  value = {
    for key in local.clusterkeys :
    key => google_container_cluster.clusters[key].master_auth.0.cluster_ca_certificate
  }
}
