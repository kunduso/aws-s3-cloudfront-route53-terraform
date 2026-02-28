[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-white.svg)](https://choosealicense.com/licenses/unlicense/) [![GitHub pull-requests closed](https://img.shields.io/github/issues-pr-closed/kunduso/aws-s3-cloudfront-route53-terraform)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/pulls?q=is%3Apr+is%3Aclosed) [![GitHub pull-requests](https://img.shields.io/github/issues-pr/kunduso/aws-s3-cloudfront-route53-terraform)](https://GitHub.com/kunduso/aws-s3-cloudfront-route53-terraform/pull/) 
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/kunduso/aws-s3-cloudfront-route53-terraform)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/issues?q=is%3Aissue+is%3Aclosed) [![GitHub issues](https://img.shields.io/github/issues/kunduso/aws-s3-cloudfront-route53-terraform)](https://GitHub.com/kunduso/aws-s3-cloudfront-route53-terraform/issues/)
[![terraform-dns-provisioning](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-dns.yml/badge.svg)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-dns.yml)  
[![terraform-infra-provisioning](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-infrastructure.yml/badge.svg)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-infrastructure.yml) [![deploy-content](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-content.yml/badge.svg)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/deploy-content.yml) [![checkov-scan](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/code-scan.yml/badge.svg)](https://github.com/kunduso/aws-s3-cloudfront-route53-terraform/actions/workflows/code-scan.yml)

## Introduction

This repository demonstrates how to deploy a secure static website on AWS using Terraform with Amazon S3, CloudFront, Route 53, AWS Certificate Manager (ACM), and AWS KMS. The solution implements a three-stage deployment architecture that separates DNS management, infrastructure provisioning, and content deployment for better maintainability and security.

The infrastructure leverages enterprise-grade security features including private S3 buckets with Origin Access Control, end-to-end encryption with customer-managed KMS keys, DNSSEC for DNS integrity, and automated HTTPS enforcement. The deployment process is fully automated through GitHub Actions workflows with OIDC authentication, eliminating the need for long-lived credentials.

For a detailed walkthrough of this implementation, check out the comprehensive blog post: [Deploy Secure Static Websites with Amazon S3, CloudFront, and Route 53 using Terraform](https://skundunotes.com/2026/02/27/deploy-secure-static-websites-with-amazon-s3-cloudfront-and-route-53-using-terraform/)

## Architecture Overview
![Architecture Diagram](https://skdevops.wordpress.com/wp-content/uploads/2026/02/125-image-1.png)
**Stage 1:** Provision the Route 53 hosted zone
<br/> **Stage 2:** Deploy S3 buckets, CloudFront distribution, and
<br/> **Stage 3:** Deploy content and invalidate cache.

### Architecture

The solution uses the following AWS services:

- **Amazon Route 53** — Hosted zone with A records (root + www) and DNSSEC enabled
- **Amazon CloudFront** — CDN distribution with Origin Access Control (OAC), HTTPS redirect, custom error pages, and access logging
- **Amazon S3** — Two private buckets: one for website content, one for error pages and CloudFront access logs
- **AWS Certificate Manager (ACM)** — SSL/TLS certificate with DNS validation
- **AWS KMS** — Encryption keys for S3 buckets, SSM parameters, and DNSSEC signing
- **AWS SSM Parameter Store** — Stores infrastructure outputs for cross-stage communication

## Deployment Stages

| Stage | Folder | Workflow | Description |
|-------|--------|----------|-------------|
| 1 | `dns/` | [`deploy-dns.yml`](.github/workflows/deploy-dns.yml) | Route 53 hosted zone + DNSSEC |
| 2 | `infrastructure/` | [`deploy-infrastructure.yml`](.github/workflows/deploy-infrastructure.yml) | S3 buckets, CloudFront, ACM, KMS, Route 53 records, SSM |
| 3 | `content/` | [`deploy-content.yml`](.github/workflows/deploy-content.yml) | S3 sync + CloudFront cache invalidation |

Stage 1 must complete (including nameserver update at your domain registrar) before Stage 2 can run. Stage 3 reads infrastructure outputs from SSM Parameter Store, so it depends on Stage 2.

## Key Features

**Three-Stage Deployment Architecture:**
- Isolated DNS, infrastructure, and content deployment workflows
- SSM Parameter Store enables cross-stage communication
- Independent state management for each deployment layer

**Enterprise-Grade Security:**
- Private S3 buckets with Origin Access Control (OAC) and SigV4 signing
- End-to-end encryption: KMS keys for S3, SSM parameters, and DNSSEC signing
- TLS 1.2 minimum with automatic HTTPS redirect
- DNSSEC-enabled Route 53 hosted zone for DNS integrity
- OIDC authentication for GitHub Actions (no long-lived credentials)

**Production-Ready Features:**
- Global content delivery via CloudFront CDN
- Custom error pages (404/500) with dedicated S3 bucket
- CloudFront and S3 access logging for audit trails
- Automated cache invalidation on content updates
- S3 versioning with 90-day retention for rollback capability

**Cost & Compliance:**
- Infracost integration for infrastructure cost estimation
- Checkov security scanning in CI/CD pipeline
- Automated deployment reduces manual errors and operational overhead

## Prerequisites

For this code to function without errors, create an OpenID Connect identity provider in Amazon Identity and Access Management that has a trust relationship with this GitHub repository. You can read about it [here](https://skundunotes.com/2023/02/28/securely-integrate-aws-credentials-with-github-actions-using-openid-connect/) to get a detailed explanation with steps.

Store the `ARN` of the `IAM Role` as a GitHub secret named `IAM_ROLE` which is referenced in the workflow files.

For Infracost integration in this repository, the `INFRACOST_API_KEY` needs to be stored as a repository secret. It is referenced in the [`deploy-infrastructure.yml`](./.github/workflows/deploy-infrastructure.yml) GitHub Actions workflow file.

You can read about that at - [integrate Infracost with GitHub Actions](https://skundunotes.com/2023/07/17/estimate-aws-cloud-resource-cost-with-infracost-terraform-and-github-actions/).

### Additional Requirements

- An S3 bucket for Terraform remote state — update the `bucket` value in `dns/backend.tf` and `infrastructure/backend.tf`
- A registered domain with access to change its nameservers at your domain registrar
- Ensure the IAM role has permissions to create and manage all resources including Route 53, S3, CloudFront, ACM, KMS, and SSM

## Project Structure

```
├── dns/                        # Stage 1: Route 53 + DNSSEC
│   ├── route53.tf              # Hosted zone, KSK, DNSSEC
│   ├── backend.tf              # Terraform remote state
│   ├── provider.tf             # AWS providers (us-east-2 + us-east-1)
│   ├── variables.tf            # Region, domain name
│   └── outputs.tf              # Nameservers, hosted zone ID
├── infrastructure/             # Stage 2: S3, CloudFront, ACM, KMS
│   ├── acm.tf                  # SSL certificate + DNS validation
│   ├── storage.tf              # Website S3 bucket + KMS key
│   ├── cloudfront-logging.tf   # Ops S3 bucket (error pages + logs)
│   ├── cloudfront.tf           # Distribution, OAC, bucket policies
│   ├── error-pages.tf          # Upload 404/500 HTML to ops bucket
│   ├── error-pages/            # Custom error page HTML files
│   │   ├── 404.html
│   │   └── 500.html
│   ├── route53.tf              # A records (root + www) → CloudFront
│   ├── ssm.tf                  # SSM parameter + KMS key
│   ├── data.tf                 # Data sources (hosted zone, cache policies)
│   ├── backend.tf              # Terraform remote state
│   ├── provider.tf             # AWS providers (us-east-2 + us-east-1)
│   ├── variables.tf            # Region, app name, domain name
│   └── outputs.tf              # Distribution ID, domain, bucket name
├── content/                    # Stage 3: Static website files
│   └── index.html
└── .github/workflows/
    ├── deploy-dns.yml           # Stage 1 workflow
    ├── deploy-infrastructure.yml # Stage 2 workflow
    └── deploy-content.yml       # Stage 3 workflow
```


If you want to check the pipeline logs, click on the **Build Badges** at the top of this README.

## Related Notes

- [Automate Route 53 hosted zone, ACM, and Load Balancer with Terraform](https://skundunotes.com/2025/03/25/automate-amazon-route-53-hosted-zone-acm-and-load-balancer-provisioning-with-terraform-and-github-actions/)
- [Configure DNSSEC for Route 53 hosted zone using Terraform](https://skundunotes.com/2025/04/17/configure-dnssec-for-amazon-route-53-hosted-zone-using-terraform/)
- [Securely integrate AWS credentials with GitHub Actions using OIDC](https://skundunotes.com/2023/02/28/securely-integrate-aws-credentials-with-github-actions-using-openid-connect/)
- [Estimate AWS cloud resource cost with Infracost, Terraform, and GitHub Actions](https://skundunotes.com/2023/07/17/estimate-aws-cloud-resource-cost-with-infracost-terraform-and-github-actions/)

## Contributing
If you find any issues or have suggestions for improvement, feel free to open an issue or submit a pull request. Contributions are always welcome!

## License

This code is released under the Unlicense License. See [LICENSE](LICENSE).
