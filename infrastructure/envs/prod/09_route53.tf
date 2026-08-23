
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.tags
}


# use this if  you want route 53 to route traffic to your alb

# resource "aws_route53_record" "alb_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = module.alb.dns_name
#     zone_id                = module.alb.zone_id
#     evaluate_target_health = true
#   }
# }


output "name_servers" {
  description = "The Name Servers to update at your registrar"
  value       = aws_route53_zone.main.name_servers
}


# The Route 53 Alias (The DNS Cutover)
resource "aws_route53_record" "api_gateway_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    # pointing to the regional endpoint of the Gateway
    name                   = aws_apigatewayv2_domain_name.boutique_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.boutique_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}


# The API Gateway Custom Domain (The TLS Edge)
resource "aws_apigatewayv2_domain_name" "boutique_domain" {
  domain_name = var.domain_name

  domain_name_configuration {
    # using the exact certificate used for your ALB
    certificate_arn = module.acm.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# The API Mapping (Connecting the Domain to the Gateway Stage)
resource "aws_apigatewayv2_api_mapping" "boutique_mapping" {
  api_id      = aws_apigatewayv2_api.boutique_gateway.id
  domain_name = aws_apigatewayv2_domain_name.boutique_domain.id
  stage       = aws_apigatewayv2_stage.default_stage.id
}

