# ---------------------------------------------------------------------------
# Cloud Armor — WAF policy for the external HTTPS load balancer
#
# NOTE: only a rate-limiting rule is defined below. The OWASP Top 10
# preconfigured WAF rules (sqli-stable, xss-stable, lfi-stable, etc.) that
# the platform baseline requires were never added after the policy was
# first stood up for basic bot throttling.
# ---------------------------------------------------------------------------

resource "google_compute_security_policy" "referralmesh_waf" {
  name = "referralmesh-waf-policy"

  rule {
    action   = "rate_based_ban"
    priority = 1000

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = 200
        interval_sec = 60
      }

      ban_duration_sec = 300
    }

    description = "Throttle abusive clients"
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
