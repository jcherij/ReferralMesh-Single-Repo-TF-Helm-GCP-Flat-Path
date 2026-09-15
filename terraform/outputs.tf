output "lb_ip_address" {
  value = google_compute_global_address.lb_ip.address
}

output "cloudsql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "referral_documents_bucket" {
  value = google_storage_bucket.referral_documents.name
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}
