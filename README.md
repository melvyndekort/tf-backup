# tf-backup

Terraform configuration for managing backup infrastructure including S3 buckets and Backblaze B2 storage.

## Features

- AWS S3 backup buckets with lifecycle policies
- Backblaze B2 bucket management
- IAM policies for backup access
- KMS encryption for S3 buckets

## Usage

```bash
make decrypt
cd terraform
terraform plan
terraform apply
make encrypt
```
