
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.tags
}


resource "aws_route53_record" "alb_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}


output "name_servers" {
  description = "The Name Servers to update at your registrar"
  value       = aws_route53_zone.main.name_servers
}