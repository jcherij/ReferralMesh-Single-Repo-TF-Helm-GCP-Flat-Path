# ---------------------------------------------------------------------------
# Artifact Registry
# ---------------------------------------------------------------------------

resource "google_artifact_registry_repository" "referralmesh_images" {
  location      = var.gcp_region
  repository_id = "referralmesh"
  format        = "DOCKER"
  description   = "Container images for ReferralMesh services (GKE workloads + Cloud Run)"
}
