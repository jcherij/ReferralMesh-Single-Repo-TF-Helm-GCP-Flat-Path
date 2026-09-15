# ---------------------------------------------------------------------------
# Monitoring & alerting
# ---------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "platform_oncall" {
  display_name = "Platform Engineering On-call"
  type         = "slack"

  labels = {
    channel_name = "#platform-oncall"
  }
}

resource "google_monitoring_notification_channel" "app_team_slack" {
  display_name = "ReferralMesh App Team"
  type         = "slack"

  labels = {
    channel_name = "#referralmesh-alerts"
  }
}

resource "google_monitoring_uptime_check_config" "referral_api_uptime" {
  display_name = "referral-api uptime"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path = "/healthz"
    port = 443
    use_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.gcp_project_id
      host       = "referrals.example.com"
    }
  }
}

resource "google_monitoring_alert_policy" "uptime_referral_api" {
  display_name = "referral-api uptime check failing"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.platform_oncall.id]

  conditions {
    display_name = "Uptime check failure"
    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "180s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "error_rate_referral_api" {
  display_name = "referral-api 500 error volume high"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.app_team_slack.id]

  conditions {
    # condition_threshold filters can only alert on a single metric
    # stream's rate, not a ratio, so this tracks absolute 500-count
    # volume rather than "error rate as a % of traffic." A true
    # percentage-of-traffic SLO alert needs a
    # condition_monitoring_query_language block computing
    # errors / total as an MQL ratio, which is out of scope for this
    # fixture.
    display_name = "500 responses > 1/s over 5m"
    condition_threshold {
      filter          = "resource.type=\"prometheus_target\" AND metric.type=\"prometheus.googleapis.com/http_requests_total/counter\" AND resource.labels.namespace=\"referralmesh\" AND resource.labels.job=\"referral-api\" AND metric.labels.code=\"500\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "latency_referral_api" {
  display_name = "referral-api p99 latency high"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.app_team_slack.id]

  conditions {
    display_name = "p99 latency > 2s"
    condition_threshold {
      filter          = "resource.type=\"prometheus_target\" AND metric.type=\"prometheus.googleapis.com/http_request_duration_seconds/histogram\" AND resource.labels.namespace=\"referralmesh\" AND resource.labels.job=\"referral-api\""
      comparison      = "COMPARISON_GT"
      threshold_value = 2
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "sql_disk_utilization" {
  display_name = "Cloud SQL disk utilization high"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.platform_oncall.id]

  conditions {
    display_name = "Disk utilization > 85%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}
