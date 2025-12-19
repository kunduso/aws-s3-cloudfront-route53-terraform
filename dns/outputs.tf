output "route53_nameservers" {
  description = "Route53 nameservers to configure in Squarespace"
  value       = aws_route53_zone.main.name_servers
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}