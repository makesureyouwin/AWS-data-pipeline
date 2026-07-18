terraform {
  backend "s3" {
    bucket         = "harini-terraform-state-2026-hb8428"
    key            = "pipeline/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}