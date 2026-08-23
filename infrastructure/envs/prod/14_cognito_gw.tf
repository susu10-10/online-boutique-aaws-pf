resource "aws_cognito_user_pool" "boutique_users" {
  name = "online-boutique-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = false
  }

  # Security Hardening: Prevent users from changing their own attributes maliciously
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Account Recovery
  auto_verified_attributes = ["email"]
}


# Cognito App client for API Gateway 

resource "aws_cognito_user_pool_client" "boutique_frontend_client" {
  name                = "online-boutique-frontend-client"
  user_pool_id        = aws_cognito_user_pool.boutique_users.id
  generate_secret     = false # for modern single-page interacting with the API GW
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}


#  AWS API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "boutique_gateway" {
  name          = "online-boutique-gateway"
  protocol_type = "HTTP"
}

#  Cognito JWT Authorizer
resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.boutique_gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    # Mathematically binds the Gateway to your specific User Pool
    issuer   = "https://${aws_cognito_user_pool.boutique_users.endpoint}"
    audience = [aws_cognito_user_pool_client.boutique_frontend_client.id]
  }
}

# VPC Link & Security Group
resource "aws_security_group" "vpc_link_sg" {
  name        = "online-boutique-vpc-link-sg"
  description = "Allow API Gateway VPC Link to route to ALB"
  vpc_id      = module.vpc.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apigatewayv2_vpc_link" "internal_bridge" {
  name               = "boutique-vpc-link"
  security_group_ids = [aws_security_group.vpc_link_sg.id]
  # Drops the bridge into your exact private subnets from the outputs
  subnet_ids         = module.vpc.private_subnets 
}

# The Routing Integration & Stage

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id           = aws_apigatewayv2_api.boutique_gateway.id
  integration_type = "HTTP_PROXY"
  
  integration_uri  = module.alb.listeners["https"].arn
  
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.internal_bridge.id
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.boutique_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
  
  # Every request requires a valid Cognito token
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.boutique_gateway.id
  name        = "$default"
  auto_deploy = true
}