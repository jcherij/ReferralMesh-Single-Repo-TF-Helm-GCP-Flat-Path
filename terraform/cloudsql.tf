# ---------------------------------------------------------------------------
# Cloud SQL (Postgres) — primary transactional store, holds PHI
# ---------------------------------------------------------------------------

resource "google_compute_global_address" "sql_private_ip_range" {
  name          = "referralmesh-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip_range.name]
}

# Single-zone instance. Was provisioned this way to save cost during the
# design-partner pilot and never migrated to a regional/HA configuration.
resource "google_sql_database_instance" "main" {
  name             = "referralmesh-pg-prod"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-custom-4-16384"
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }
  }

  encryption_key_name = google_kms_crypto_key.sql_key.id

  deletion_protection = true
}

resource "google_sql_database" "referralmesh" {
  name     = "referralmesh"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app_user" {
  name     = "referralmesh_app"
  instance = google_sql_database_instance.main.name
  password = "changeme-replace-with-secret-manager-output" # tfsec: override at apply time via -var
}
