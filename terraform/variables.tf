variable "gcp_project_id" {
  description = "GCP project hosting ReferralMesh production resources"
  type        = string
  default     = "referralmesh-prod-4471"
}

variable "gcp_region" {
  description = "Primary region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "Name of the shared GKE cluster this app deploys into (owned by Platform Engineering, not this module)"
  type        = string
  default     = "shared-prod-gke"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name used for tagging/labeling"
  type        = string
  default     = "referralmesh"
}

variable "ingress_nginx_neg_name" {
  description = "Name of the GKE-managed standalone NEG backing the ingress-nginx Service, as emitted onto its cloud.google.com/neg-status annotation after the Helm release deploys. Populate after first `helm upgrade --install`, not before."
  type        = string
  default     = "k8s1-referralmesh-ingress-nginx-controller-80"
}
