# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "ssm_key" {
  description             = "KMS key for SSM parameter encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
resource "aws_kms_alias" "ssm_key_alias" {
  name          = "alias/${var.name}-encrypt-ssm"
  target_key_id = aws_kms_key.ssm_key.key_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy
resource "aws_kms_key_policy" "ssm_key" {
  key_id = aws_kms_key.ssm_key.id
  policy = data.aws_iam_policy_document.ssm_key_policy.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "ssm_key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:Create*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = [aws_kms_key.ssm_key.arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "Allow SSM to use the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.ssm_key.arn]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter
resource "aws_ssm_parameter" "infra_output" {
  name        = "/${var.name}/output"
  description = "Infrastructure layer resources."
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_key.id
  value = jsonencode({
    "s3_bucket_name" : "${aws_s3_bucket.website.bucket}",
    "cloudfront_distribution_id" : "${aws_cloudfront_distribution.website.id}",
    "cloudfront_domain" : "${aws_cloudfront_distribution.website.domain_name}",
    "cloudfront_ops_bucket" : "${aws_s3_bucket.cloudfront_ops.bucket}"
  })
}