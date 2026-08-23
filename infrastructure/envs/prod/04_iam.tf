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
#     ]
#   })
# }

resource "aws_iam_policy" "github_deploy_policy" {
  name        = "${var.project_name}-github-deploy-policy"
  description = "Permissions for GitHub Actions to plan and apply the full online-boutique stack"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 1. Edge & Identity (API GW, Cognito, ACM, Route53)
        Effect = "Allow"
        Action = [
          "apigateway:*",
          "cognito-idp:*",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:GetChange"
        ]
        Resource = [
          "arn:aws:apigateway:us-east-1::/*",
          "arn:aws:cognito-idp:us-east-1:767397659229:userpool/*",
          "arn:aws:acm:us-east-1:767397659229:certificate/*",
          "arn:aws:route53:::hostedzone/*",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        # 2. Compute, Network & Routing (ECS, EC2, ELB, Servicediscovery, Autoscaling)
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "servicediscovery:*",
          "application-autoscaling:*"
        ]
        Resource = "*"
      },
      {
        # 3. Serverless Bridge & Cryptographic Vault (SQS, SNS, Lambda, SSM, ECR)
        Effect = "Allow"
        Action = [
          "sqs:*",
          "sns:*",
          "lambda:*",
          "ssm:*",
          "ecr:*"
        ]
        Resource = [
          "arn:aws:sqs:us-east-1:767397659229:*",
          "arn:aws:sns:us-east-1:767397659229:*",
          "arn:aws:lambda:us-east-1:767397659229:function:*",
          "arn:aws:ssm:us-east-1:767397659229:parameter/online-boutique/*",
          "arn:aws:ecr:us-east-1:767397659229:repository/*"
        ]
      },
      {
        # 4. Observability (CloudWatch Logs)
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:us-east-1:767397659229:log-group:*"
      },
      {
        # 5. IAM Automation 
        Effect = "Allow"
        Action = [
          "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:AttachRolePolicy",
          "iam:DetachRolePolicy", "iam:GetRolePolicy", "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
          "iam:PassRole", "iam:GetPolicy", "iam:GetPolicyVersion", "iam:CreatePolicy",
          "iam:DeletePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions", "iam:GetOpenIDConnectProvider"
        ]
        Resource = [
          "arn:aws:iam::767397659229:role/*",
          "arn:aws:iam::767397659229:policy/*",
          "arn:aws:iam::767397659229:oidc-provider/token.actions.githubusercontent.com"
        ]
      },
      {
        # 6. Terraform State Management
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          "arn:aws:s3:::online-boutique-tfstate-767397659229",
          "arn:aws:s3:::online-boutique-tfstate-767397659229/*"
        ]
      },
      {
        # 7. Terraform Metadata & Auditing Exception (AWS APIs that require wildcard resources)
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "cognito-idp:DescribeUserPoolDomain",
          "route53:ListTagsForResource",
          "logs:ListTagsForResource",
          "lambda:GetEventSourceMapping",
          "lambda:ListEventSourceMappings"
        ]
        Resource = "*"
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