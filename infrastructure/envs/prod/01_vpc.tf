
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  # no nat gw needed
  enable_nat_gateway = false
  single_nat_gateway = false

  #dns support is needed for vpc ep to be able to resolve correctly
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags ECS/ALB expect to find on the subnets for auto-discovery
  tags = var.tags
  public_subnet_tags = {
    Tier = "public"
  }
  private_subnet_tags = {
    Tier = "private"
  }
}



