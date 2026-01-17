# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "cloudfront_ops" {
  bucket        = "${var.name}-cloudfront-ops-${random_string.bucket_suffix.result}"
  force_destroy = true

  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #skip-reason: Logging bucket cannot log to itself (infinite loop). No secondary logging bucket needed for CloudFront logs.

  #checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  #skip-reason: No event-driven workflows required for CloudFront logging and error pages.

  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled
  #skip-reason: Cross-region replication not required for CloudFront logging bucket. Single region sufficient for log storage.

  #checkov:skip=CKV2_AWS_6:Ensure that S3 bucket has a Public Access block
  #skip-reason: Public access block is configured separately. CloudFront logging requires specific ACL settings.
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  #checkov:skip=CKV2_AWS_65:Ensure access control lists for S3 buckets are disabled
  #skip-reason: CloudFront logging requires ACL access. BucketOwnerPreferred provides security while enabling logging.
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
resource "aws_s3_bucket_acl" "cloudfront_ops" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_ops,
    aws_s3_bucket_public_access_block.cloudfront_ops
  ]
  bucket = aws_s3_bucket.cloudfront_ops.id
  acl    = "private"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true

  #checkov:skip=CKV_AWS_53:Ensure S3 bucket has block public ACLS enabled
  #skip-reason: CloudFront logging requires ACL access. Security maintained through bucket policies.

  #checkov:skip=CKV_AWS_55:Ensure S3 bucket has ignore public ACLs enabled
  #skip-reason: CloudFront logging requires ACL access. Security maintained through bucket policies.
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id
  versioning_configuration {
    status = "Enabled"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    id     = "abort_incomplete_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "manage_log_files"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

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
  }

  rule {
    id     = "manage_error_pages"
    status = "Enabled"

    filter {
      prefix = "error-pages/"
    }

    # Keep error pages indefinitely, but clean up incomplete uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}