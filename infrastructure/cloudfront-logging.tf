# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "cloudfront_ops" {
  bucket = "${var.name}-cloudfront-ops-${random_string.bucket_suffix.result}"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    id     = "manage_log_files"
    status = "Enabled"

    # Move logs to cheaper storage classes over time
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete old logs after 1 year to control costs
    expiration {
      days = 365
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}