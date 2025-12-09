terraform {
  backend "s3" {
    bucket       = "kunduso-terraform-remote-bucket"
    encrypt      = true
    key          = "tf/aws-s3-cloudfront-route53-terraform/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}