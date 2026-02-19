output "backup_application_key_id" {
  value = b2_application_key.backup.application_key_id
}

output "backup_application_key" {
  value     = b2_application_key.backup.application_key
  sensitive = true
}

output "backup_bucket" {
  value = aws_s3_bucket.backup.id
}

output "b2_consolidated_bucket_name" {
  value = b2_bucket.mdekort_backup.bucket_name
}

output "b2_consolidated_bucket_id" {
  value = b2_bucket.mdekort_backup.bucket_id
}
