# ---------------------------------------------------------------------------
# BigQuery — de-identified analytics + audit export
# ---------------------------------------------------------------------------

resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "referralmesh_analytics"
  location                   = var.gcp_region
  default_table_expiration_ms = null

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.secrets_key.id
  }

  labels = {
    application = "referralmesh"
    environment = var.environment
    managed-by  = "terraform"
    data-class  = "internal"
  }
}

resource "google_bigquery_table" "referral_events" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "referral_events"

  schema = jsonencode([
    { name = "event_id", type = "STRING", mode = "REQUIRED" },
    { name = "event_type", type = "STRING", mode = "REQUIRED" },
    { name = "referral_ref", type = "STRING", mode = "REQUIRED" }, # de-identified reference only
    { name = "occurred_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}

resource "google_bigquery_table" "audit_export" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "audit_export"

  schema = jsonencode([
    { name = "actor", type = "STRING", mode = "REQUIRED" },
    { name = "action", type = "STRING", mode = "REQUIRED" },
    { name = "resource_ref", type = "STRING", mode = "REQUIRED" },
    { name = "occurred_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}

resource "google_bigquery_dataset_iam_member" "analytics_reader" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = google_project_iam_custom_role.referral_reader.id
  member     = "serviceAccount:${google_service_account.referral_worker.email}"
}
