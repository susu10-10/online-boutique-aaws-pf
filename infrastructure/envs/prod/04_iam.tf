# Gh OIDC IdP

module "iam_iam-github-oidc-provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
}


# The explicit permissions granted to GitHub Actions
# resource "aws_iam_policy" "github_deploy_policy" {
#   name        = "${var.project_name}-github-deploy-policy"
#   description = "Permissions for GitHub Actions to push to ECR and deploy to ECS"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["ecr:GetAuthorizationToken"]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:PutImage",
#           "ecr:InitiateLayerUpload",
#           "ecr:UploadLayerPart",
#           "ecr:CompleteLayerUpload",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "arn:aws:ecr:${var.aws_region}:*:repository/*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecs:UpdateService",
#           "ecs:DescribeServices",
#           "ecs:DescribeTaskDefinition",
#           "ecs:RegisterTaskDefinition"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect   = "Allow"
#         Action   = ["iam:PassRole"]
#         Resource = [aws_iam_role.ecs_task_execution_role.arn, aws_iam_role.ecs_task_role.arn]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:ListBucket",
#           "s3:GetObject",
#           "s3:HeadObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           "arn:aws:s3:::online-boutique-tfstate-767397659229",
#           "arn:aws:s3:::online-boutique-tfstate-767397659229/*"
#         ]
#       },
#       # IAM role/provider reads
#       {
#         Effect = "Allow"
#         Action = ["iam:GetRole"]
#         Resource = [
#           "arn:aws:iam::767397659229:role/online-boutique-ecs-task-execution-role",
#           "arn:aws:iam::767397659229:role/online-boutique-ecs-task-role",
#           "arn:aws:iam::767397659229:role/online-boutique-lambda-event-role",
#           "arn:aws:iam::767397659229:role/online-boutique-github-deploy-role"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = ["iam:GetOpenIDConnectProvider"]
#         Resource = [
#           "arn:aws:iam::767397659229:oidc-provider/token.actions.githubusercontent.com"
#         ]
#       },

#       # Route 53
#       {
#         Effect   = "Allow"
#         Action   = ["route53:GetHostedZone"]
#         Resource = ["arn:aws:route53:::hostedzone/Z09119203ES24GTLS3WTL"]
#       },

#       # SNS
#       {
#         Effect   = "Allow"
#         Action   = ["sns:GetTopicAttributes"]
#         Resource = ["arn:aws:sns:us-east-1:767397659229:online-boutique-order-notifications"]
#       },

#       # SQS
#       {
#         Effect   = "Allow"
#         Action   = ["sqs:GetQueueAttributes"]
#         Resource = ["arn:aws:sqs:us-east-1:767397659229:online-boutique-orders"]
#       },

#       # SSM Parameters
#       {
#         Effect   = "Allow"
#         Action   = ["ssm:GetParameter"]
#         Resource = ["arn:aws:ssm:us-east-1:767397659229:parameter/online-boutique/prod/*"]
#       },

#       # Cognito
#       {
#         Effect   = "Allow"
#         Action   = ["cognito-idp:DescribeUserPool"]
#         Resource = ["arn:aws:cognito-idp:us-east-1:767397659229:userpool/us-east-1_ht38iFf0D"]
#       },

#       # API Gateway v2
#       {
#         Effect   = "Allow"
#         Action   = ["apigateway:GET"]
#         Resource = ["arn:aws:apigateway:us-east-1::/apis/48l9obgib4"]
#       },

#       # ACM certificate
#       {
#         Effect   = "Allow"
#         Action   = ["acm:DescribeCertificate"]
#         Resource = ["arn:aws:acm:us-east-1:767397659229:certificate/48c23dc1-d6b8-4297-b6d4-71e2fd61890c"]
#       },

#       # ECR repository reads
#       {
#         Effect   = "Allow"
#         Action   = ["ecr:DescribeRepositories"]
#         Resource = ["arn:aws:ecr:us-east-1:767397659229:repository/online-boutique/*"]
#       },

#       # EC2 VPC read/refresh
#       {
#         Effect   = "Allow"
#         Action   = ["ec2:DescribeVpcs"]
#         Resource = ["*"]
#       },

#       # CloudWatch Logs read/refresh
#       {
#         Effect   = "Allow"
#         Action   = ["logs:DescribeLogGroups"]
#         Resource = ["*"]
#       }
#     ]
#   })
# }
resource "aws_iam_policy" "github_deploy_policy" {
  name        = "${var.project_name}-github-deploy-policy"
  description = "Permissions for GitHub Actions to plan and apply the full online-boutique stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ---------- ECR ----------
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ecr:*"]
        Resource = [
          "arn:aws:ecr:us-east-1:767397659229:repository/online-boutique/*"
        ]
      },

      # ---------- ECS ----------
      # ECS actions generally require "*" as the resource.
      {
        Effect   = "Allow"
        Action   = ["ecs:*"]
        Resource = "*"
      },

      # ---------- IAM ----------
      # Manage only the roles/policies/OIDC provider created by this project.
      {
        Effect = "Allow"
        Action = ["iam:*"]
        Resource = [
          "arn:aws:iam::767397659229:role/online-boutique-*",
          "arn:aws:iam::767397659229:policy/online-boutique-*",
          "arn:aws:iam::767397659229:oidc-provider/token.actions.githubusercontent.com"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListOpenIDConnectProviders",
          "iam:GetAccountSummary"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::767397659229:role/online-boutique-ecs-task-execution-role",
          "arn:aws:iam::767397659229:role/online-boutique-ecs-task-role",
          "arn:aws:iam::767397659229:role/online-boutique-lambda-event-role"
        ]
      },

      # ---------- Route 53 ----------
      {
        Effect = "Allow"
        Action = ["route53:*"]
        Resource = [
          "arn:aws:route53:::hostedzone/Z09119203ES24GTLS3WTL"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      },

      # ---------- SNS ----------
      {
        Effect = "Allow"
        Action = ["sns:*"]
        Resource = [
          "arn:aws:sns:us-east-1:767397659229:online-boutique-order-notifications"
        ]
      },

      # ---------- SQS ----------
      {
        Effect = "Allow"
        Action = ["sqs:*"]
        Resource = [
          "arn:aws:sqs:us-east-1:767397659229:online-boutique-orders"
        ]
      },

      # ---------- SSM Parameter Store ----------
      {
        Effect = "Allow"
        Action = ["ssm:*"]
        Resource = [
          "arn:aws:ssm:us-east-1:767397659229:parameter/online-boutique/prod/*"
        ]
      },

      # ---------- Cognito ----------
      {
        Effect = "Allow"
        Action = ["cognito-idp:*"]
        Resource = [
          "arn:aws:cognito-idp:us-east-1:767397659229:userpool/us-east-1_ht38iFf0D"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:ListUserPools"]
        Resource = "*"
      },

      # ---------- API Gateway v2 ----------
      {
        Effect = "Allow"
        Action = ["apigateway:*"]
        Resource = [
          "arn:aws:apigateway:us-east-1::/apis/*"
        ]
      },

      # ---------- ACM ----------
      {
        Effect = "Allow"
        Action = ["acm:*"]
        Resource = [
          "arn:aws:acm:us-east-1:767397659229:certificate/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:ListCertificates"
        ]
        Resource = "*"
      },

      # ---------- EC2 / VPC ----------
      # The VPC module uses a very large number of EC2 APIs.
      # Broad EC2 access is the safest way to avoid apply failures.
      {
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      },

      # ---------- CloudWatch Logs ----------
      {
        Effect = "Allow"
        Action = ["logs:*"]
        Resource = [
          "arn:aws:logs:us-east-1:767397659229:log-group:*"
        ]
      },

      # ---------- Lambda ----------
      # If your stack includes Lambda functions (likely from 12_serverless.tf).
      {
        Effect = "Allow"
        Action = ["lambda:*"]
        Resource = [
          "arn:aws:lambda:us-east-1:767397659229:function:online-boutique-*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:GetAccountSettings"]
        Resource = "*"
      },

      # ---------- S3 backend ----------
      # Keep your existing state bucket permissions.
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:HeadObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::online-boutique-tfstate-767397659229",
          "arn:aws:s3:::online-boutique-tfstate-767397659229/*"
        ]
      }
    ]
  })
}

# Gh Action Deploy/Assume  Role with Trust Relationship 

module "iam_iam-github-oidc-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "${var.project_name}-github-deploy-role"

  # deployments from main branch are allowed only
  # subjects = ["repo:susu10-10@<OWNER_ID>/online-boutique-aaws-pf@<REPO_ID>:ref:refs/heads/main"]
  subjects = [
    "repo:susu10-10@75139663/online-boutique-aaws-pf@1340715756:ref:refs/heads/main",
    "repo:susu10-10@75139663/online-boutique-aaws-pf@1340715756:pull_request"
  ]
  # # The Expanded Zero-Trust Boundary
  # subjects = [
  #   # Allow the main branch
  #   "repo:susu10-10@<OWNER_ID>/online-boutique-aaws-pf@<REPO_ID>:ref:refs/heads/main",
  #   # Allow any feature branch
  #   "repo:susu10-10@<OWNER_ID>/online-boutique-aaws-pf@<REPO_ID>:ref:refs/heads/*",
  #   # Allow Pull Request triggers
  #   "repo:susu10-10@<OWNER_ID>/online-boutique-aaws-pf@<REPO_ID>:pull_request"
  # ]

  policies = {
    DeployPolicy = aws_iam_policy.github_deploy_policy.arn
  }
}

# ECS Task Execution Role (The Agent Permissions)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS managed policy for pulling images and writing logs to the ecs task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (The Application Permissions)
# This is intentionally empty. Most microservices only talk gRPC and need zero AWS permissions.
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# Granting the Mesh access to the Serverless Buffer

resource "aws_iam_role_policy" "ecs_sqs_producer_policy" {
  name = "OnlineBoutiqueSQSProducer"
  # Replace 'aws_iam_role.ecs_task_role.id' with the actual ID of your Fargate task role
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sqs:SendMessage"
        # Referencing the exact queue you just built
        Resource = aws_sqs_queue.order_queue.arn
      }
    ]
  })
}


# x-ray policy for the ecs task role

resource "aws_iam_role_policy_attachment" "xray_daemon_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}