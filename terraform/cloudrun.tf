# ---------------------------------------------------------------------------
# Cloud Run — GCP-native compute outside the GKE cluster
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "eligibility_check_worker" {
  name     = "referralmesh-eligibility-check-worker"
  location = var.gcp_region

  template {
    service_account = google_service_account.cloudrun_eligibility_check.email

    containers {
      image = "us-docker.pkg.dev/${var.gcp_project_id}/referralmesh/eligibility-check-worker:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = google_compute_network.vpc.id
        subnetwork = google_compute_subnetwork.data_subnet.id
      }
      egress = "ALL_TRAFFIC"
    }
  }

  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}

resource "google_cloud_run_v2_service" "pdf_generator" {
  name     = "referralmesh-pdf-generator"
  location = var.gcp_region

  template {
    service_account = google_service_account.cloudrun_pdf_generator.email

    containers {
      image = "us-docker.pkg.dev/${var.gcp_project_id}/referralmesh/pdf-generator:latest"

      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
    }
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_v2_service_iam_member" "eligibility_check_invoker" {
  location = var.gcp_region
  name     = google_cloud_run_v2_service.eligibility_check_worker.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.eligibility_sync.email}"
}

# The PDF generator renders discharge-summary PDFs that include patient
# name and MRN. It was set to allow unauthenticated invocations during
# early integration testing with the design partner and that setting
# shipped to production.
resource "google_cloud_run_v2_service_iam_member" "pdf_generator_invoker_public" {
  location = var.gcp_region
  name     = google_cloud_run_v2_service.pdf_generator.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
