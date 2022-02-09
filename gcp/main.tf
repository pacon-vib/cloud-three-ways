terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.10.0"
    }
  }
}

provider "google" {
  #credentials = file("<NAME>.json")
  #project = var.gcp_project # Rely on environment variable GOOGLE_CLOUD_PROJECT
  region  = var.gcp_region
  zone    = local.gcp_zone
}

locals {
  gcp_zone = "${var.gcp_region}-a"
}

resource "google_compute_instance" "default" {
  name         = var.vm_public_hostname
  machine_type = "e2-medium"
  zone         = local.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${var.ssh_key}"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
}

output "vm_public_fqdn" {
  value = "???" # TODO
}

output "vm_public_ip_address" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}
