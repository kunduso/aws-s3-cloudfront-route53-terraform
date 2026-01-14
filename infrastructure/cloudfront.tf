# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.name}-oac"
  description                       = "OAC for ${var.name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control
resource "aws_cloudfront_origin_access_control" "error_pages" {
  name                              = "${var.name}-error-pages-oac"
  description                       = "OAC for ${var.name} error pages S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "S3-${aws_s3_bucket.website.bucket}"
  }

  # Error pages origin
  origin {
    domain_name              = aws_s3_bucket.cloudfront_ops.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.error_pages.id
    origin_id                = "S3-${aws_s3_bucket.cloudfront_ops.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  # CloudFront access logging
  logging_config {
    bucket          = aws_s3_bucket.cloudfront_ops.bucket_domain_name
    prefix          = "logs/"
    include_cookies = false
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${aws_s3_bucket.website.bucket}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  }

  # Cache behavior for error pages
  ordered_cache_behavior {
    path_pattern             = "/error-pages/*"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${aws_s3_bucket.cloudfront_ops.bucket}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Custom error pages
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error-pages/404.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error-pages/404.html"
  }

  custom_error_response {
    error_code         = 500
    response_code      = 500
    response_page_path = "/error-pages/500.html"
  }

#checkov:skip=CKV2_AWS_47:Ensure AWS CloudFront attached WAFv2 WebACL is configured with AMR for Log4j Vulnerability
#skip-reason: Static HTML content has no Log4j vulnerability. WAF adds unnecessary cost for static website.

#checkov:skip=CKV_AWS_68:CloudFront Distribution should have WAF enabled
#skip-reason: Static website with no dynamic content or user input does not require WAF protection.

#checkov:skip=CKV_AWS_310:Ensure CloudFront distributions should have origin failover configured
#skip-reason: Single S3 origin is sufficient for static website.

#checkov:skip=CKV_AWS_374:Ensure AWS CloudFront web distribution has geo restriction enabled
#skip-reason: Static website should be globally accessible without geographic restrictions.
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "cloudfront_ops_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cloudfront_ops.arn}/error-pages/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }

  statement {
    sid    = "AllowCloudFrontLogging"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudfront_ops.arn}/logs/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id
  policy = data.aws_iam_policy_document.cloudfront_ops_bucket_policy.json
}