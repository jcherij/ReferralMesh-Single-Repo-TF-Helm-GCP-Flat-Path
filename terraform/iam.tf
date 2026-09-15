# ---------------------------------------------------------------------------
# Service accounts, custom roles, IAM bindings, Workload Identity
# ---------------------------------------------------------------------------

resource "google_service_account" "referral_api" {
  account_id   = "referralmesh-referral-api"
  display_name = "ReferralMesh - referral-api workload identity"
}

resource "google_service_account" "referral_worker" {
  account_id   = "referralmesh-referral-worker"
  display_name = "ReferralMesh - referral-worker workload identity"
}

resource "google_service_account" "eligibility_sync" {
  account_id   = "referralmesh-eligibility-sync"
  display_name = "ReferralMesh - eligibility-sync workload identity"
}

resource "google_service_account" "document_processor" {
  account_id   = "referralmesh-document-processor"
  display_name = "ReferralMesh - document-processor workload identity"
}

resource "google_service_account" "notification_service" {
  account_id   = "referralmesh-notification-svc"
  display_name = "ReferralMesh - notification-service workload identity"
}

resource "google_service_account" "cloudrun_eligibility_check" {
  account_id   = "referralmesh-run-eligibility"
  display_name = "ReferralMesh - Cloud Run eligibility-check-worker"
}

resource "google_service_account" "cloudrun_pdf_generator" {
  account_id   = "referralmesh-run-pdf-gen"
  display_name = "ReferralMesh - Cloud Run pdf-generator"
}

resource "google_project_iam_custom_role" "referral_reader" {
  role_id     = "referralmesh_referralReader"
  title       = "ReferralMesh Referral Reader"
  description = "Read-only access to referral BigQuery views for analytics workloads"
  permissions = [
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.jobs.create",
  ]
}

resource "google_storage_bucket_iam_member" "referral_documents_writer" {
  bucket = google_storage_bucket.referral_documents.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.document_processor.email}"
}

resource "google_storage_bucket_iam_member" "processed_referrals_reader" {
  bucket = google_storage_bucket.processed_referrals.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.referral_api.email}"
}

resource "google_pubsub_topic_iam_member" "referral_worker_publisher" {
  topic  = google_pubsub_topic.referral_matched.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.referral_worker.email}"
}

resource "google_pubsub_subscription_iam_member" "eligibility_sync_subscriber" {
  subscription = google_pubsub_subscription.eligibility_check_request_sub.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.cloudrun_eligibility_check.email}"
}

resource "google_secret_manager_secret_iam_member" "referral_api_db_password" {
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.referral_api.email}"
}

resource "google_kms_crypto_key_iam_member" "cloudsql_sa_key_user" {
  crypto_key_id = google_kms_crypto_key.sql_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
}

# Granted during an incident to unblock a report export and never scoped
# back down. Bypasses least-privilege for one workload identity.
resource "google_project_iam_member" "notification_service_editor" {
  project = var.gcp_project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.notification_service.email}"
}

resource "google_service_account_iam_member" "referral_api_wi" {
  service_account_id = google_service_account.referral_api.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.gcp_project_id}.svc.id.goog[referralmesh/referral-api]"
}

resource "google_service_account_iam_member" "referral_worker_wi" {
  service_account_id = google_service_account.referral_worker.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.gcp_project_id}.svc.id.goog[referralmesh/referral-worker]"
}

resource "google_service_account_iam_member" "eligibility_sync_wi" {
  service_account_id = google_service_account.eligibility_sync.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.gcp_project_id}.svc.id.goog[referralmesh/eligibility-sync]"
}

resource "google_service_account_iam_member" "document_processor_wi" {
  service_account_id = google_service_account.document_processor.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.gcp_project_id}.svc.id.goog[referralmesh/document-processor]"
}

data "google_project" "current" {
  project_id = var.gcp_project_id
}
