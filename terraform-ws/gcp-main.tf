resource "google_compute_network" "gcp_k8s_vnet" {
  name = "gcp-k8s-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_k8s_subnet" {

  depends_on = [
    google_compute_network.gcp_k8s_vnet
  ]

  name          = "gcp-k8s-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = "asia-south1"
  network       = google_compute_network.gcp_k8s_vnet.id
}

resource "google_compute_firewall" "gcp_k8s_firewall" {

  depends_on = [
    google_compute_network.gcp_k8s_vnet
  ]

  name    = "gcp-allowall-firewall"
  network = google_compute_network.gcp_k8s_vnet.id

  allow {
    protocol = "tcp"
  }

  source_tags = ["internet"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "gcp_k8s_slave" {

  depends_on = [
    google_compute_subnetwork.gcp_k8s_subnet
  ]

  name         = "gcp-k8s-slave"
  machine_type = "e2-medium"
  zone         = "asia-south1-c"

  metadata = {
      ssh-keys = "centos:${file("../k8s-multi-cloud-key-public.pub")}"
  }

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-8"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_k8s_subnet.self_link
    access_config {}
  }
}