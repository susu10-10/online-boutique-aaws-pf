
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTPS from internet for the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_rules = ["all-all"]
}

module "ecs_tasks_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-ecs-tasks-sg"
  description = "ingress: only from ALB and internal tasks"
  vpc_id      = module.vpc.vpc_id

  # Ingress from ALB to the frontend service
  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Inbound from ALB to Frontend"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  # Allow tasks to communicate with each other internally (gRPC/HTTP mesh)
  ingress_with_self = [
    {
      rule        = "all-all"
      description = "Allow internal task-to-task communication"
    }
  ]

  egress_rules = ["all-all"]
}


# 3. The API Boundary: VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpce-sg"
  description = "Allow TLS inbound from VPC tasks to AWS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}