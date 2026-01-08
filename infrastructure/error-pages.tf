# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
resource "aws_s3_object" "error_404" {
  bucket       = aws_s3_bucket.cloudfront_ops.id
  key          = "error-pages/404.html"
  source       = "${path.module}/error-pages/404.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/error-pages/404.html")
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
resource "aws_s3_object" "error_500" {
  bucket       = aws_s3_bucket.cloudfront_ops.id
  key          = "error-pages/500.html"
  source       = "${path.module}/error-pages/500.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/error-pages/500.html")
}