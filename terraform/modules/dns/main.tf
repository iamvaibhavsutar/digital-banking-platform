variable "domain_name"  { type = string } # e.g. "yourdomain.in"
variable "alb_dns_name" { type = string }
variable "alb_zone_id"  { type = string }

resource "aws_route53_zone" "this" { name = var.domain_name }

resource "aws_acm_certificate" "this" {
  domain_name       = "bank.${var.domain_name}"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "validation" {
  for_each = { for o in aws_acm_certificate.this.domain_validation_options : o.domain_name => o }
  zone_id  = aws_route53_zone.this.zone_id
  name     = each.value.resource_record_name
  type     = each.value.resource_record_type
  records  = [each.value.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

resource "aws_route53_record" "bank" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "bank.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

output "certificate_arn" { value = aws_acm_certificate_validation.this.certificate_arn }
output "name_servers"    { value = aws_route53_zone.this.name_servers }
