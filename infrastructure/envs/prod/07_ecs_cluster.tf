module "ecs_cl8" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0.0"

  cluster_name = "${var.project_name}-ecs-cluster"



  # Cluster capacity providers
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
      #base   = 20
    }

  }

  tags = var.tags
}

# the internal dns for mircosvc to microsvc comms
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "onlineboutique.internal"
  description = "Internal service discovery namespace for gRPC microservices"
  vpc         = module.vpc.vpc_id
}