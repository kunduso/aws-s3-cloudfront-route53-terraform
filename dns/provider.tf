# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
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
# Provider for us-east-1 (required for DNS query logging)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags {
    tags = {
      Source = "https://github.com/kunduso/add-aws-elb-ec2-private-subnet-terraform"
    }
  }
}