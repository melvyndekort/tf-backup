# tf-backup

Terraform configuration for managing off-site backup infrastructure using AWS S3 and Backblaze B2.

## Overview

This repository manages backup storage infrastructure with a hybrid approach optimized for cost and access patterns:

- **AWS S3 Deep Archive**: Static/append-only data (photos) - $0.00099/GB/month
- **Backblaze B2**: Frequently changing data (backups, syncthing) - $0.006/GB/month

**Total cost**: ~$1.35/month for 726GB of off-site backups

## Infrastructure

### AWS S3 Buckets

#### mdekort.backup
Primary backup bucket with lifecycle management for photos.

**Features:**
- KMS encryption using `alias/generic` key
- Lifecycle policy: `photos/` prefix transitions to Deep Archive after 2 days
- Access logging to central logs bucket
- Private ACL with public access blocked
- IAM user `lmbackup` has full access

**Storage classes:**
- S3 Standard (2-day buffer): ~8GB
- Deep Archive (permanent): ~620GB photos

**Use case:** Long-term photo storage with 12-48 hour restore time

#### mdekort.portainer
Portainer backup bucket with automatic cleanup.

**Features:**
- KMS encryption using `alias/generic` key
- Lifecycle policy: Auto-delete after 7 days
- Access logging to central logs bucket
- Private ACL with public access blocked

**Use case:** Temporary Portainer configuration backups

### Backblaze B2 Buckets

#### mdekort-backup (NEW - Consolidated)
Single restic repository using tags for logical separation.

**Features:**
- AES256 SSE-B2 encryption
- Private bucket
- Restic tags for dataset separation:
  - `--tag backups` - Database dumps, container backups (~100GB)
  - `--tag syncthing` - Syncthing sync data (~2GB)

**Benefits:**
- Better deduplication across datasets
- Simpler management (one bucket, one restic repo)
- Lower overhead
- Easier monitoring and cost tracking

**Use case:** All frequently changing backup data with incremental snapshots

#### mdekort-backup-lmserver (LEGACY)
Legacy bucket for lmserver backups. Will be removed after migration validation (30 days).

**Current size:** 145GB (after cleanup from 833GB)  
**Status:** Active but deprecated

#### mdekort-backup-syncthing (LEGACY)
Legacy bucket for syncthing backups. Will be removed after migration validation (30 days).

**Current size:** 2.5GB  
**Status:** Active but deprecated

### IAM Configuration

#### lmbackup User Policy
Managed IAM policy attached to the `lmbackup` user (created in tf-aws).

**Permissions:**
- S3 List/Get on backup and portainer buckets
- S3 full access to objects in backup and portainer buckets
- KMS GenerateDataKey and Decrypt for generic key (encryption/decryption)

#### B2 Application Key
Application key `lmbackup` with capabilities:
- listBuckets
- listFiles
- readFiles
- writeFiles
- deleteFiles

**Scope:** All B2 buckets in account

## Architecture

### Backup Strategy

```
storage-1 (10.204.10.20)
├── /var/srv/storage/backups/ (100GB) → restic → B2 (--tag backups)
├── /var/srv/storage/syncthing/ (2GB) → restic → B2 (--tag syncthing)
└── /var/srv/storage/photos/ (624GB) → rclone → S3 → Deep Archive

compute-1 (10.204.10.21)
└── Creates backups → NFS to storage-1 → Included in B2 backup
```

### Why Hybrid Strategy?

**B2 for frequently changing data:**
- Cheaper storage ($0.006/GB vs S3 Standard $0.023/GB)
- Free egress up to 10GB/day (slow restore acceptable)
- Perfect for restic incremental backups with deduplication

**S3 Deep Archive for photos:**
- Cheapest storage ($0.00099/GB vs B2 $0.006/GB)
- Photos are append-only (rarely modified)
- 12-48 hour restore delay acceptable for disaster recovery
- No need for restic overhead (simple rclone sync)

### Cost Breakdown

**Monthly costs:**
- B2: 102GB × $0.006/GB = $0.61
- S3 Deep Archive: 624GB × $0.00099/GB = $0.62
- S3 Standard (2-day buffer): ~$0.01
- **Total: $1.24/month (~€1.15/month, ~€14/year)**

**Restore costs (full 726GB):**
- B2: Free (11 days at 10GB/day) or $9.18 (fast)
- S3: $1.56 (bulk retrieval) + $56.16 (egress) = $57.72
- **Total: $57.72 (slow) or $66.90 (fast)**

## Remote State Dependencies

This module depends on `tf-aws` remote state for:
- `generic_kms_alias_arn` - KMS key for S3 encryption
- `generic_kms_key_arn` - KMS key ARN for IAM policy
- `access_logs_bucket` - S3 access logging destination
- `lmbackup_name` - IAM user name for policy attachment

## Secrets Management

Secrets are encrypted using AWS KMS with encryption context `target=tf-backup`.

**Secrets file structure** (`terraform/secrets.yaml`):
```yaml
b2:
  application_key_id: <b2-key-id>
  application_key: <b2-secret-key>
```

**Encryption/Decryption:**
```bash
make decrypt  # Decrypt secrets before terraform operations
make encrypt  # Re-encrypt secrets after editing
```

**Note:** Secrets file is gitignored. Only encrypted version is committed.

## Usage

### Prerequisites

1. AWS credentials configured (via `assume` command)
2. Terraform >= 1.0
3. Access to `mdekort.tfstate` S3 bucket
4. KMS key `alias/generic` exists (managed in tf-aws)

### Standard Workflow

```bash
# Decrypt secrets
make decrypt

# Navigate to terraform directory
cd terraform

# Initialize (first time only)
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Re-encrypt secrets
cd ..
make encrypt
```

### GitHub Actions

Terraform operations are automated via GitHub Actions:
- **Workflow:** `.github/workflows/terraform.yml`
- **Trigger:** Push to main branch
- **Authentication:** GitHub OIDC (no long-lived credentials)
- **State locking:** Enabled via S3 backend

## Outputs

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `backup_application_key_id` | B2 application key ID | No |
| `backup_application_key` | B2 application key secret | Yes |
| `backup_bucket` | S3 backup bucket name | No |
| `b2_consolidated_bucket_name` | New consolidated B2 bucket name | No |
| `b2_consolidated_bucket_id` | New consolidated B2 bucket ID | No |

## Migration Status

**Current state (2026-02-19):**
- ✅ New consolidated bucket `mdekort-backup` created
- ✅ S3 photos backup operational (weekly sync)
- 🔄 B2 backup migration in progress
- ⏳ Legacy buckets will be removed after 30-day validation

## Backup Tools

### Restic (B2)
- Incremental backups with deduplication
- Snapshot-based (easy point-in-time restore)
- Encryption at rest
- Tag-based separation in single repository
- Retention: 7 daily, 4 weekly, 6 monthly (~6 months)

### Rclone (S3)
- Simple file sync (like rsync for cloud)
- No overhead for append-only data
- Works with S3 lifecycle policies
- Metadata always accessible (even in Deep Archive)

## Monitoring

Backup operations are monitored via:
- **ntfy notifications** - Success/failure alerts
- **Scheduler logs** - Detailed execution logs on storage-1
- **Gatus health checks** - Service availability monitoring

## Security

- **S3 encryption:** KMS using `alias/generic` key
- **B2 encryption:** AES256 SSE-B2
- **IAM:** Least privilege access for `lmbackup` user
- **Secrets:** KMS encrypted with encryption context
- **Access:** Private buckets, public access blocked
- **Logging:** All S3 access logged to central bucket

## Related Documentation

- [Backup Migration Plan](https://github.com/melvyndekort/network-documentation/blob/main/planning/backup-migration.md) - Detailed migration strategy
- [Server Infrastructure](https://github.com/melvyndekort/network-documentation/blob/main/infrastructure/servers.md) - Server backup configuration
- [tf-aws](https://github.com/melvyndekort/tf-aws) - Core AWS infrastructure

## License

See [LICENSE](LICENSE) file.

## Maintainer

Melvyn de Kort (@melvyndekort)
