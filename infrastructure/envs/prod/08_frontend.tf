module "frontend_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "frontend"
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

  # Container definition(s)
  container_definitions = {

    frontend = {
      essential = true
      image     = "${module.ecr["frontend"].repository_url}:latest"

      portMappings = [
        {
          name          = "frontend"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonlyRootFilesystem = false

      environment = [
        { name = "PORT", value = "8080" },
        { name = "ENV_PLATFORM", value = "local" },
        { name = "ENABLE_TRACING", value = "1" },
        { name = "ENABLE_PROFILER", value = "0" },
        { name = "CYMBAL_BRANDING", value = "false" },
        { name = "ENABLE_ASSISTANT", value = "false" },
        # The Telemetry Patch to Satisfy the Go binary's routing requirement
        { name = "COLLECTOR_SERVICE_ADDR", value = "localhost:2000" }
      ]

      secrets = [
        { name = "PRODUCT_CATALOG_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_productcatalog.arn },
        { name = "CURRENCY_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_currency.arn },
        { name = "CART_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_cart.arn },
        { name = "RECOMMENDATION_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_recommendation.arn },
        { name = "SHIPPING_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_shipping.arn },
        { name = "CHECKOUT_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_checkout.arn },
        { name = "AD_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_ad.arn },
        { name = "SHOPPING_ASSISTANT_SERVICE_ADDR", valueFrom = aws_ssm_parameter.global_shoppingassistant.arn }
      ]

    },
    # The Sidecar: AWS X-Ray Daemon running alongside the frontend
    xray-daemon = {
      image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/xray-daemon:latest"
      essential = true # If the telemetry agent dies, Fargate restarts the whole task

      portMappings = [
        {
          containerPort = 2000
          hostPort      = 2000
          protocol      = "udp"
        }
      ]

      # The Hardening: Even the telemetry agent gets locked down
      readonlyRootFilesystem = false
    }
  }


  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["frontend_tg"].arn
      container_name   = "frontend"
      container_port   = 8080
    }
  }

  # Deploy into private subnets
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}