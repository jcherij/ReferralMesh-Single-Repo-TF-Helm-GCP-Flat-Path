# ---------------------------------------------------------------------------
# VPC, subnets, NAT, firewall
# ---------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "referralmesh-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "referralmesh-app-subnet"
  ip_cidr_range = "10.20.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.24.0.0/14"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.28.0.0/20"
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata              = "INCLUDE_ALL_METADATA"
  }
}

# NOTE: this subnet carries PHI-bearing traffic (Cloud SQL private IP, GCS
# private access for referral-documents). Flow Logs are NOT enabled here.
resource "google_compute_subnetwork" "data_subnet" {
  name          = "referralmesh-data-subnet"
  ip_cidr_range = "10.20.16.0/22"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "referralmesh-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "referralmesh-nat"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.app_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "deny_all_ingress" {
  name      = "referralmesh-deny-all-ingress"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ingress_from_lb" {
  name      = "referralmesh-allow-lb-health-checks"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  # Google's documented health-check and LB source ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["referralmesh-backend"]
}

resource "google_compute_firewall" "allow_internal" {
  name      = "referralmesh-allow-internal"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = [
    google_compute_subnetwork.app_subnet.ip_cidr_range,
    google_compute_subnetwork.data_subnet.ip_cidr_range,
  ]
}

# Temporary rule added for a debugging session against the referral-worker
# box and never removed. Grants direct access to Postgres from anywhere.
resource "google_compute_firewall" "allow_debug_wide_open" {
  name      = "referralmesh-allow-debug-postgres"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["referralmesh-data"]
}
