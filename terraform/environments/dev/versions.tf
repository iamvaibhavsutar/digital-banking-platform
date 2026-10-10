terraform {
  required_version = ">= 1.10"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.80" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
  backend "s3" {
    # bucket is passed at init:  terraform init -backend-config="bucket=<state-bucket>"
    key          = "digital-banking/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # native S3 locking (Terraform >= 1.10)
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
  default_tags {
    tags = {
      Project = "digital-banking"
      Env     = var.env
      Managed = "terraform"
    }
  }
}
