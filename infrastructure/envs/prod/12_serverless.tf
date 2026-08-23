# SNS Topic and Subscription

resource "aws_sns_topic" "order_notifications" {
  name = "online-boutique-order-notifications"
}


resource "aws_sns_topic_subscription" "user_emails_target" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "email"
  endpoint  = "ghostnerdb@gmail.com"
}


# SQS Resource

resource "aws_sqs_queue" "order_queue" {
  name                      = "online-boutique-orders"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
}



# Lambda Role Policy
resource "aws_iam_role_policy" "lambda_event_policy" {
  name = "lambda-event-policy"
  role = aws_iam_role.lambda_event_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.order_queue.arn
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.order_notifications.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

# Lambda Execution role

resource "aws_iam_role" "lambda_event_role" {
  name = "online-boutique-lambda-event-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}



# Packaging the Lambda 

data "archive_file" "lambda_zip_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function

# Function using the layer
resource "aws_lambda_function" "order_processor" {
  filename         = data.archive_file.lambda_zip_package.output_path
  function_name    = "online-boutique-order-processor"
  role             = aws_iam_role.lambda_event_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip_package.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.order_notifications.arn
    }
  }
}



# Event Source Mapping to connect SQS to Lambda

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.order_processor.arn
  batch_size       = 1

  tags = var.tags
}