# ---------------------------------------------------------------------------
# Logging & audit
# ---------------------------------------------------------------------------

resource "google_logging_project_sink" "audit_sink" {
  name                   = "referralmesh-audit-sink"
  destination            = "storage.googleapis.com/${google_storage_bucket.audit_logs_archive.name}"
  filter                 = "logName:\"cloudaudit.googleapis.com\""
  unique_writer_identity = true
}

resource "google_logging_project_sink" "phi_access_sink" {
  name                   = "referralmesh-phi-access-sink"
  destination            = "storage.googleapis.com/${google_storage_bucket.audit_logs_archive.name}"
  filter                 = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.referral_documents.name}\""
  unique_writer_identity = true
}

# Each sink's writer_identity is only known after creation, so the bucket
# grant has to reference it directly rather than a static service account.
resource "google_storage_bucket_iam_member" "audit_sink_writer" {
  bucket = google_storage_bucket.audit_logs_archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_sink.writer_identity
}

resource "google_storage_bucket_iam_member" "phi_access_sink_writer" {
  bucket = google_storage_bucket.audit_logs_archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.phi_access_sink.writer_identity
}

resource "google_logging_metric" "failed_auth_attempts" {
  name   = "referralmesh-failed-auth-attempts"
  filter = "resource.type=\"k8s_container\" AND jsonPayload.message=~\"auth_failed\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_logging_metric" "phi_access_denied" {
  name   = "referralmesh-phi-access-denied"
  filter = "resource.type=\"gcs_bucket\" AND protoPayload.status.code!=0"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Data Access audit logging is explicitly enabled for Cloud SQL and Cloud
# Storage. Pub/Sub (which carries the eligibility-check-request payload,
# itself PHI-bearing) was left on the platform default and never added
# here.
resource "google_project_iam_audit_config" "data_access_logging" {
  project = var.gcp_project_id
  service = "storage.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_iam_audit_config" "data_access_logging_sql" {
  project = var.gcp_project_id
  service = "sqladmin.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
