# New consolidated bucket (single restic repo with tags)
resource "b2_bucket" "mdekort_backup" {
  bucket_name = "mdekort-backup"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

# Old buckets - keep for now, will remove after migration validation
resource "b2_bucket" "mdekort_backup_lmserver" {
  bucket_name = "mdekort-backup-lmserver"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

resource "b2_bucket" "mdekort_backup_syncthing" {
  bucket_name = "mdekort-backup-syncthing"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}
