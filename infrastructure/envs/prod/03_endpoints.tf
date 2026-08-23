
module "vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = module.vpc.private_subnets

  endpoints = {
    s3 = {
      # interface endpoint
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.project_name}-s3-vpce" }
    },
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-ecr-api-vpce" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-ecr-dkr-vpce" }
    },
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-logs-vpce" }
    },
    secretsmanager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-secrets-vpce" }
    },
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-ssm-vpce" }
    },
    xray = {
      service             = "xray"
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.project_name}-xray-vpce" }
    }
  }

}
