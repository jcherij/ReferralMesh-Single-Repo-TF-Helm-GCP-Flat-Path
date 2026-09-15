# ---------------------------------------------------------------------------
# Pub/Sub — event backbone between referral-api, referral-worker,
# eligibility-sync (Cloud Run) and notification-service
# ---------------------------------------------------------------------------

resource "google_pubsub_topic" "referral_intake" {
  name = "referral-intake"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "referral_matched" {
  name = "referral-matched"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "eligibility_check_request" {
  name = "eligibility-check-request"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "eligibility_check_result" {
  name = "eligibility-check-result"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "notification_dispatch" {
  name = "notification-dispatch"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "referral_intake_dlq" {
  name = "referral-intake-dlq"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_topic" "eligibility_check_request_dlq" {
  name = "eligibility-check-request-dlq"
  kms_key_name = google_kms_crypto_key.pubsub_key.id
}

resource "google_pubsub_subscription" "referral_intake_sub" {
  name  = "referral-intake-worker-sub"
  topic = google_pubsub_topic.referral_intake.name

  ack_deadline_seconds = 60

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.referral_intake_dlq.id
    max_delivery_attempts = 5
  }
}

resource "google_pubsub_subscription" "referral_matched_sub" {
  name  = "referral-matched-notification-sub"
  topic = google_pubsub_topic.referral_matched.name

  ack_deadline_seconds = 30

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.referral_intake_dlq.id
    max_delivery_attempts = 5
  }
}

resource "google_pubsub_subscription" "eligibility_check_request_sub" {
  name  = "eligibility-check-request-run-sub"
  topic = google_pubsub_topic.eligibility_check_request.name

  ack_deadline_seconds = 120

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.eligibility_check_request_dlq.id
    max_delivery_attempts = 5
  }
}

resource "google_pubsub_subscription" "eligibility_check_result_sub" {
  name  = "eligibility-check-result-api-sub"
  topic = google_pubsub_topic.eligibility_check_result.name

  ack_deadline_seconds = 30

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.eligibility_check_request_dlq.id
    max_delivery_attempts = 5
  }
}

# Added late in the project to fan notifications out to the notification
# worker. The DLQ wiring that every other subscription has was never added.
resource "google_pubsub_subscription" "notification_dispatch_sub" {
  name  = "notification-dispatch-worker-sub"
  topic = google_pubsub_topic.notification_dispatch.name

  ack_deadline_seconds = 30
}
