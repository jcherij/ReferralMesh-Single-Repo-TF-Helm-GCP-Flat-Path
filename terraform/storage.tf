# ---------------------------------------------------------------------------
# GCS buckets
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "referral_documents" {
  name          = "${var.gcp_project_id}-referral-documents"
  location      = var.gcp_region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs_key.id
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    application  = "referralmesh"
    environment  = var.environment
    managed-by   = "terraform"
    data-class   = "phi"
  }
}

resource "google_storage_bucket" "processed_referrals" {
  name          = "${var.gcp_project_id}-processed-referrals"
  location      = var.gcp_region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs_key.id
  }

  uniform_bucket_level_access = true

  labels = {
    application = "referralmesh"
    environment = var.environment
    managed-by  = "terraform"
    data-class  = "phi"
  }
}

resource "google_storage_bucket" "audit_logs_archive" {
  name          = "${var.gcp_project_id}-audit-logs-archive"
  location      = var.gcp_region
  storage_class = "COLDLINE"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs_key.id
  }

  uniform_bucket_level_access = true

  retention_policy {
    retention_period = 189216000 # 6 years, HIPAA minimum
  }

  labels = {
    application = "referralmesh"
    environment = var.environment
    managed-by  = "terraform"
    data-class  = "phi"
  }
}

# Holds app config exports (feature flags, non-PHI reference data). Created
# early in the project and never brought in line with the versioning
# baseline once the app started writing customer-facing config to it.
resource "google_storage_bucket" "app_config" {
  name          = "${var.gcp_project_id}-app-config"
  location      = var.gcp_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  labels = {
    application = "referralmesh"
    environment = var.environment
    managed-by  = "terraform"
    data-class  = "internal"
  }
}

resource "google_storage_bucket_iam_member" "audit_logs_writer" {
  bucket = google_storage_bucket.audit_logs_archive.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.notification_service.email}"
}
