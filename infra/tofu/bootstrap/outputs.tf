output "state_bucket_name" {
  description = "Bucket name."
  value       = google_storage_bucket.tofu_state.name
}
