# ---------------------------------------------------------------------------
# Cloud Scheduler
# ---------------------------------------------------------------------------

resource "google_cloud_scheduler_job" "nightly_reconciliation" {
  name      = "referralmesh-nightly-reconciliation"
  schedule  = "0 2 * * *"
  time_zone = "America/Chicago"

  http_target {
    http_method = "POST"
    uri         = "https://referrals.example.com/internal/jobs/reconcile"

    oidc_token {
      service_account_email = google_service_account.referral_worker.email
    }
  }
}

resource "google_cloud_scheduler_job" "eligibility_recheck" {
  name      = "referralmesh-eligibility-recheck"
  schedule  = "*/30 * * * *"
  time_zone = "America/Chicago"

  pubsub_target {
    topic_name = google_pubsub_topic.eligibility_check_request.id
    data       = base64encode("{\"trigger\":\"scheduled_recheck\"}")
  }
}

resource "google_cloud_scheduler_job" "audit_export_trigger" {
  name      = "referralmesh-audit-export-trigger"
  schedule  = "0 3 * * 0"
  time_zone = "America/Chicago"

  http_target {
    http_method = "POST"
    uri         = "https://referrals.example.com/internal/jobs/export-audit"

    oidc_token {
      service_account_email = google_service_account.notification_service.email
    }
  }
}
