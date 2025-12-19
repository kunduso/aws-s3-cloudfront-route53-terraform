# https://registry.terraform.io/language/values/variables
variable "region" {
  description = "Infrastructure region"
  type        = string
  default     = "us-east-2"
}

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
  default     = "kunduso.com"
}