terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "aws-tf-state-aps1" # Must match your exact S3 bucket name
    key            = "global/s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "prod-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}