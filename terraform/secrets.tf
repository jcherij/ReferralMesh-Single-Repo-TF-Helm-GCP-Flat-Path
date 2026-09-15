# ---------------------------------------------------------------------------
# Secret Manager
# ---------------------------------------------------------------------------

resource "google_secret_manager_secret" "db_password" {
  secret_id = "referralmesh-db-password"

  replication {
    user_managed {
      replicas {
        location = var.gcp_region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets_key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret" "api_signing_key" {
  secret_id = "referralmesh-api-signing-key"

  replication {
    user_managed {
      replicas {
        location = var.gcp_region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets_key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret" "cloudsql_client_cert" {
  secret_id = "referralmesh-cloudsql-client-cert"

  replication {
    user_managed {
      replicas {
        location = var.gcp_region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets_key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret" "eligibility_api_key" {
  secret_id = "referralmesh-eligibility-api-key"

  replication {
    user_managed {
      replicas {
        location = var.gcp_region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets_key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret" "notification_provider_key" {
  secret_id = "referralmesh-notification-provider-key"

  replication {
    user_managed {
      replicas {
        location = var.gcp_region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets_key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret_iam_member" "api_signing_key_accessor" {
  secret_id = google_secret_manager_secret.api_signing_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.referral_api.email}"
}

resource "google_secret_manager_secret_iam_member" "eligibility_api_key_accessor" {
  secret_id = google_secret_manager_secret.eligibility_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.eligibility_sync.email}"
}

# Granted directly to an on-call engineer's personal account so they could
# debug a delivery failure over a weekend. Never revoked.
resource "google_secret_manager_secret_iam_member" "notification_key_oncall_user" {
  secret_id = google_secret_manager_secret.notification_provider_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "user:oncall-engineer@referralmesh.example.com"
}
