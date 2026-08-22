module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name = var.domain_name
  zone_id     = aws_route53_zone.main.zone_id

  validation_method = "DNS"

  #   subject_alternative_names = [
  #     "*.my-domain.com",
  #     "app.sub.my-domain.com",
  #   ]

  wait_for_validation = true

  tags = var.tags
}