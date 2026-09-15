# ---------------------------------------------------------------------------
# External HTTPS load balancer fronting referral-api (via GKE ingress-nginx
# NEG) plus HTTP -> HTTPS redirect
# ---------------------------------------------------------------------------

resource "google_compute_global_address" "lb_ip" {
  name = "referralmesh-lb-ip"
}

resource "google_compute_managed_ssl_certificate" "referralmesh_cert" {
  name = "referralmesh-cert"

  managed {
    domains = ["referrals.example.com"]
  }
}

resource "google_compute_health_check" "referral_api_hc" {
  name = "referralmesh-referral-api-hc"

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }

  check_interval_sec = 10
  timeout_sec        = 5
}

# GKE's NEG controller manages this NEG's endpoint membership directly
# (pod IPs come and go with every rollout/scale event) once the
# ingress-nginx Service is annotated with cloud.google.com/neg. Terraform
# only needs to look the NEG up by name, not create or populate it — the
# name itself is emitted by GKE onto the Service's neg-status annotation
# after the Helm chart deploys, and is passed in here via a variable
# rather than hardcoded.
data "google_compute_network_endpoint_group" "ingress_nginx_neg" {
  name = var.ingress_nginx_neg_name
  zone = "${var.gcp_region}-a"
}

resource "google_compute_backend_service" "referral_api_backend" {
  name                  = "referralmesh-referral-api-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group = data.google_compute_network_endpoint_group.ingress_nginx_neg.id
  }

  health_checks = [google_compute_health_check.referral_api_hc.id]
  security_policy = google_compute_security_policy.referralmesh_waf.id

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "referralmesh_urlmap" {
  name            = "referralmesh-urlmap"
  default_service = google_compute_backend_service.referral_api_backend.id
}

resource "google_compute_target_https_proxy" "referralmesh_proxy" {
  name             = "referralmesh-https-proxy"
  url_map          = google_compute_url_map.referralmesh_urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.referralmesh_cert.id]
}

resource "google_compute_global_forwarding_rule" "referralmesh_https" {
  name                  = "referralmesh-https-fr"
  target                = google_compute_target_https_proxy.referralmesh_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_url_map" "http_redirect" {
  name = "referralmesh-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "referralmesh_http_proxy" {
  name    = "referralmesh-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "referralmesh_http_redirect" {
  name                  = "referralmesh-http-fr"
  target                = google_compute_target_http_proxy.referralmesh_http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
