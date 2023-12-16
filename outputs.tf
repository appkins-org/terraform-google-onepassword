output "app_url" {
  value = google_cloud_run_v2_service.default.uri
}

output "service_account_email" {
  value = google_service_account.connect.email
}
