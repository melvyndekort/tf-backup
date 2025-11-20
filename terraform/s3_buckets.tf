# Backup
resource "aws_s3_bucket" "backup" {
  bucket = "mdekort.backup"
}

resource "aws_s3_bucket_acl" "backup" {
  bucket = aws_s3_bucket.backup.id

  acl = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id = "archive"

    filter {
      prefix = "photos/"
    }

    transition {
      days          = 2
      storage_class = "DEEP_ARCHIVE"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.terraform_remote_state.tf_aws.outputs.generic_kms_alias_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "backup" {
  bucket = aws_s3_bucket.backup.id

  target_bucket = data.terraform_remote_state.tf_aws.outputs.access_logs_bucket
  target_prefix = "${aws_s3_bucket.backup.bucket}/"
}

# Portainer
resource "aws_s3_bucket" "portainer" {
  bucket = "mdekort.portainer"
}

resource "aws_s3_bucket_acl" "portainer" {
  bucket = aws_s3_bucket.portainer.id

  acl = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "portainer" {
  bucket = aws_s3_bucket.portainer.id

  rule {
    id = "autocleanup"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portainer" {
  bucket = aws_s3_bucket.portainer.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.terraform_remote_state.tf_aws.outputs.generic_kms_alias_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "portainer" {
  bucket                  = aws_s3_bucket.portainer.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "portainer" {
  bucket = aws_s3_bucket.portainer.id

  target_bucket = data.terraform_remote_state.tf_aws.outputs.access_logs_bucket
  target_prefix = "${aws_s3_bucket.portainer.bucket}/"
}
