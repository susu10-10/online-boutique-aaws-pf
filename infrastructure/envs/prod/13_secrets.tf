
# Granting Fargate Access to the ssm parameter store

resource "aws_iam_role_policy" "ecs_ssm_read_policy" {
  name = "OnlineBoutiqueSSMReadAccess"
  # Note: Ensure this matches the exact name of your execution role variable
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        # Zero Trust: Only allow access to this specific project's parameters
        Resource = "arn:aws:ssm:us-east-1:767397659229:parameter/online-boutique/prod/*"
      }
    ]
  })
}

# Aws ssm parameter store

resource "aws_ssm_parameter" "cart_redis_addr" {
  name  = "/online-boutique/prod/cartservice/redis_addr" # naming convention: /project/environment/service/key
  type  = "String"
  value = "redis-cart.onlineboutique.internal:6379"
}

resource "aws_ssm_parameter" "global_productcatalog" {
  name  = "/online-boutique/prod/global/productcatalog_addr" # naming convention: /project/environment/service/key
  type  = "String"
  value = "productcatalogservice.onlineboutique.internal:3550"
}


resource "aws_ssm_parameter" "global_currency" {
  name  = "/online-boutique/prod/global/currency_addr" # naming convention: /project/environment/service/key
  type  = "String"
  value = "currencyservice.onlineboutique.internal:7000"
}

resource "aws_ssm_parameter" "global_cart" {
  name  = "/online-boutique/prod/global/cart_addr"
  type  = "String"
  value = "cartservice.onlineboutique.internal:7070"
}

resource "aws_ssm_parameter" "global_recommendation" {
  name  = "/online-boutique/prod/global/recommendation_addr"
  type  = "String"
  value = "recommendationservice.onlineboutique.internal:8080"
}

resource "aws_ssm_parameter" "global_shipping" {
  name  = "/online-boutique/prod/global/shipping_addr"
  type  = "String"
  value = "shippingservice.onlineboutique.internal:50051"
}

resource "aws_ssm_parameter" "global_checkout" {
  name  = "/online-boutique/prod/global/checkout_addr"
  type  = "String"
  value = "checkoutservice.onlineboutique.internal:5050"
}

resource "aws_ssm_parameter" "global_ad" {
  name  = "/online-boutique/prod/global/ad_addr"
  type  = "String"
  value = "adservice.onlineboutique.internal:9555"
}

resource "aws_ssm_parameter" "global_shoppingassistant" {
  name  = "/online-boutique/prod/global/shoppingassistant_addr"
  type  = "String"
  value = "shoppingassistantservice.onlineboutique.internal:80"
}

resource "aws_ssm_parameter" "global_payment" {
  name  = "/online-boutique/prod/global/payment_addr"
  type  = "String"
  value = "paymentservice.onlineboutique.internal:50051"
}

resource "aws_ssm_parameter" "global_email" {
  name  = "/online-boutique/prod/global/email_addr"
  type  = "String"
  value = "emailservice.onlineboutique.internal:8080"
}