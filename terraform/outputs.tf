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
