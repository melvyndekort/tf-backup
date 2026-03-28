# tf-backup

> For global standards, way-of-workings, and pre-commit checklist, see `~/.kiro/steering/behavior.md`

## Role

Cloud Engineer specializing in Terraform and backup infrastructure.

## Backup Strategy

- **AWS S3 Deep Archive**: Static/append-only data (photos) — ~$0.001/GB/month
- **Backblaze B2**: Frequently changing data (backups, syncthing) — $0.006/GB/month
- Total: ~$1.35/month for ~726GB

## Repository Structure

- `terraform/s3_buckets.tf` — AWS S3 buckets (Deep Archive for photos)
- `terraform/b2_buckets.tf` — Backblaze B2 buckets
- `terraform/keys.tf` — B2 application keys
- `terraform/iam.tf` — IAM users/policies for backup access
- `terraform/outputs.tf` — B2 keys and bucket info
- `terraform/secrets.tf` — KMS-encrypted secrets loading
- `Makefile` — `decrypt`, `encrypt`, `clean_secrets`

## Outputs Consumed by Other Repos

- `homelab` — B2 application key ID + key (via `make fetch-remote-secrets` in homelab)

## Terraform Details

- Backend: S3 key `tf-backup.tfstate` in `mdekort-tfstate-075673041815`
- Providers: AWS `~> 6.0`, B2 `~> 0.9`
- Secrets: KMS context `target=tf-backup`

## Related Repositories

- `~/src/melvyndekort/homelab` — Consumes B2 keys for backup containers
