terraform {
  required_version = ">= 1.10"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.80" } }
}
provider "aws" { region = "ap-south-1" }

variable "bucket_name" { type = string } # globally unique, e.g. bank-tfstate-<account-id>

resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name
  lifecycle { prevent_destroy = true } # remove at teardown (Section 17.7)
}
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
output "bucket" { value = aws_s3_bucket.state.id }
