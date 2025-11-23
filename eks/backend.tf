terraform {
  required_version = "~> 1.9.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
  backend "s3" {
    bucket  = "kklabsuser130803-s3"
    region  = "us-east-1"
    key     = "eks/terraform.tfstate"
    encrypt = true
  }
}
provider "aws" {
  region = "us-east-1"
}
