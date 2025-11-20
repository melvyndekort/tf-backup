variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}
