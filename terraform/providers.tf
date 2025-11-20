terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.9"
    }
  }

  backend "s3" {
    bucket       = "mdekort.tfstate"
    key          = "tf-backup.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "b2" {
  application_key_id = local.secrets.b2.application_key_id
  application_key    = local.secrets.b2.application_key
}
