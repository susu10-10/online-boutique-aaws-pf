#dns record for cloud map for the product catalog


resource "aws_service_discovery_service" "productcatalog" {
  name = "productcatalogservice"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    # this allows multiple containers to share the same DNs name
    routing_policy = "MULTIVALUE"
  }

}


# Product catalog service

module "productcatalog_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "productcatalogservice"
  cluster_arn = module.ecs_cl8.cluster_arn

  cpu    = 256
  memory = 512
  # shell access without ssh keys
  enable_execute_command = true

  # attach iam role created in iam.tf file
  create_tasks_iam_role = false
  tasks_iam_role_arn    = aws_iam_role.ecs_task_role.arn

  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn

  #Disable Auto Scaling to bypass the Permissions Boundary
  enable_autoscaling       = false
  autoscaling_min_capacity = 0
  autoscaling_max_capacity = 0

  # Wire the container to the Cloud Map registry defined above
  service_registries = {
    registry_arn = aws_service_discovery_service.productcatalog.arn
  }

  # Container definition(s)
  container_definitions = {

    productcatalog = {
      essential = true
      image     = "${module.ecr["productcatalogservice"].repository_url}:latest"

      portMappings = [
        {
          name          = "grpc"
          containerPort = 3550
          hostPort      = 3550
          protocol      = "tcp"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonlyRootFilesystem = false

      # Disable the GCP Stackdriver profiler to save CPU cycles
      environment = [
        { name = "DISABLE_PROFILER", value = "1" }
      ]

    }
  }

  # Deploy into private subnets only
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}