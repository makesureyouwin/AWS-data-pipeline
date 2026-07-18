provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "raw_data" {
  bucket = "harini-pipeline-raw-data-2026"

  tags = {
    Project     = "real-aws-data-pipeline"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "raw_data_versioning" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}