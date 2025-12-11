# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Source = "https://github.com/kunduso/aws-s3-cloudfront-route53-terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Source = "https://github.com/kunduso/aws-s3-cloudfront-route53-terraform"
    }
  }
}