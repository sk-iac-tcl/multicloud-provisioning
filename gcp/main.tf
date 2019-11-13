resource "google_storage_bucket" "terraform_state" {
  name     = "sktcl-terraform-demo-state-kubeflow"
  location = "asia-northeast1"
}

resource "google_container_cluster" "practice" {
  name               = "kubeflow2"
  zone               = "${data.google_compute_zones.available.names[0]}"
  initial_node_count = 2

  node_version       = "1.12"
  min_master_version = "1.12"

  additional_zones = [
    "${data.google_compute_zones.available.names[1]}"
  ]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}