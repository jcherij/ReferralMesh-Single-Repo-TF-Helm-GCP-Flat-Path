# ---------------------------------------------------------------------------
# KMS — customer-managed keys for PHI/PII encryption at rest
# ---------------------------------------------------------------------------

resource "google_kms_key_ring" "main" {
  name     = "referralmesh-keyring"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "sql_key" {
  name            = "referralmesh-sql-cmek"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "gcs_key" {
  name            = "referralmesh-gcs-cmek"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "pubsub_key" {
  name            = "referralmesh-pubsub-cmek"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "secrets_key" {
  name            = "referralmesh-secrets-cmek"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

# Service-agent grants so each product can actually use its CMEK. Without
# these, the encryption { default_kms_key_name = ... } / kms_key_name = ...
# arguments elsewhere in this module reference keys the service identity
# can't call, and creation of the encrypted resource fails.
resource "google_kms_crypto_key_iam_member" "gcs_service_agent_key_user" {
  crypto_key_id = google_kms_crypto_key.gcs_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "pubsub_service_agent_key_user" {
  crypto_key_id = google_kms_crypto_key.pubsub_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "secretmanager_service_agent_key_user" {
  crypto_key_id = google_kms_crypto_key.secrets_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "bigquery_service_agent_key_user" {
  crypto_key_id = google_kms_crypto_key.secrets_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.current.number}@bigquery-encryption.iam.gserviceaccount.com"
}
