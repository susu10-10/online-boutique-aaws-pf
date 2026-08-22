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
      readonlyRootFilesystem = true

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

# =============================================================================
# CARTSERVICE (Port 7070)
# =============================================================================
resource "aws_service_discovery_service" "cart" {
  name = "cartservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "cart_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "cartservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.cart.arn
  }

  container_definitions = {
    cartservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/cartservice:latest"
      image = "${module.ecr["cartservice"].repository_url}:latest"

      portMappings = [
        {
          name          = "grpc"
          containerPort = 7070
          hostPort      = 7070
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      environment = [
        { name = "REDIS_ADDR", value = "redis-cart.onlineboutique.internal:6379" },
        { name = "DISABLE_PROFILER", value = "1" },
        { name = "ASPNETCORE_HTTP_PORTS", value = "7070" },
        { name = "DOTNET_EnableDiagnostics", value = "0" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}

# =============================================================================
# 2. CHECKOUTSERVICE (Port 5050)
# =============================================================================
resource "aws_service_discovery_service" "checkout" {
  name = "checkoutservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "checkout_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "checkoutservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.checkout.arn
  }

  container_definitions = {
    checkoutservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/checkoutservice:latest"
      image = "${module.ecr["checkoutservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 5050
          hostPort      = 5050
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true


      environment = [
        { name = "PORT", value = "5050" },
        { name = "PRODUCT_CATALOG_SERVICE_ADDR", value = "productcatalogservice.onlineboutique.internal:3550" },
        { name = "SHIPPING_SERVICE_ADDR", value = "shippingservice.onlineboutique.internal:50051" },
        { name = "PAYMENT_SERVICE_ADDR", value = "paymentservice.onlineboutique.internal:50051" },
        { name = "EMAIL_SERVICE_ADDR", value = "emailservice.onlineboutique.internal:8080" },
        { name = "CURRENCY_SERVICE_ADDR", value = "currencyservice.onlineboutique.internal:7000" },
        { name = "CART_SERVICE_ADDR", value = "cartservice.onlineboutique.internal:7070" },
        { name = "DISABLE_PROFILER", value = "1" },
        { name = "ENABLE_TRACING", value = "0" },
        { name = "ENABLE_PROFILER", value = "0" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}


# =============================================================================
#  currencyservice: Port 7000
# =============================================================================
resource "aws_service_discovery_service" "currency" {
  name = "currencyservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "currency_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "currencyservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.currency.arn
  }

  container_definitions = {
    currencyservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/currencyservice:latest"
      image = "${module.ecr["currencyservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 7000
          hostPort      = 7000
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      environment = [
        { name = "PORT", value = "7000" },
        { name = "DISABLE_PROFILER", value = "true" },
        { name = "ENABLE_TRACING", value = "0" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}

# =============================================================================
# paymentservice: Port 50051
# =============================================================================
resource "aws_service_discovery_service" "payment" {
  name = "paymentservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "payment_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "paymentservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.payment.arn
  }

  container_definitions = {
    paymentservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/paymentservice:latest"
      image = "${module.ecr["paymentservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 50051
          hostPort      = 50051
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      # The Invisible Dependency Mesh
      environment = [
        { name = "PORT", value = "50051" },
        { name = "DISABLE_PROFILER", value = "true" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}


# =============================================================================
# shippingservice: Port 50051
# =============================================================================
resource "aws_service_discovery_service" "shipping" {
  name = "shippingservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "shipping_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "shippingservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.shipping.arn
  }

  container_definitions = {
    shippingservice = {
      essential = true
      # The Skin in the Game: Ensuring the exact ECR path is referenced
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/shippingservice:latest"
      image = "${module.ecr["shippingservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 50051
          hostPort      = 50051
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      environment = [
        { name = "APP_PORT", value = "50051" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}

# =============================================================================
# emailservice: Port 8080
# =============================================================================
resource "aws_service_discovery_service" "email" {
  name = "emailservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "email_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "emailservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.email.arn
  }

  container_definitions = {
    emailservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/emailservice:latest"
      image = "${module.ecr["emailservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      # The Invisible Dependency Mesh
      environment = [
        { name = "PORT", value = "8080" },
        { name = "DISABLE_PROFILER", value = "true" },
        { name = "ENABLE_TRACING", value = "0" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}


# =============================================================================
#  recommendationservice: Port 8080
# =============================================================================
resource "aws_service_discovery_service" "recommendations" {
  name = "recommendationservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "recommendations_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "recommendationservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.recommendations.arn
  }

  container_definitions = {
    recommendationservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/recommendationservice:latest"
      image = "${module.ecr["recommendationservice"].repository_url}:latest"
      portMappings = [
        {
          name          = "grpc"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      environment = [
        { name = "PORT", value = "8080" },
        { name = "PRODUCT_CATALOG_SERVICE_ADDR", value = "productcatalogservice.onlineboutique.internal:3550" },
        { name = "ENABLE_TRACING", value = "0" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}

# =============================================================================
# adservice: Port 9555
# =============================================================================
resource "aws_service_discovery_service" "adservice" {
  name = "adservice"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "adservice" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "adservice"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.adservice.arn
  }

  container_definitions = {
    adservice = {
      essential = true
      #image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/adservice:latest"
      image = "${module.ecr["adservice"].repository_url}:latest"

      portMappings = [
        {
          name          = "grpc"
          containerPort = 9555
          hostPort      = 9555
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      environment = [
        { name = "PORT", value = "9555" },
        { name = "DISABLE_PROFILER", value = "1" }
      ]
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}



# =============================================================================
# REDIS CACHE (Port 6379) - Dependency for cartservice
# =============================================================================
resource "aws_service_discovery_service" "redis" {
  name = "redis-cart"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

module "redis_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0.0"

  name        = "redis-cart"
  cluster_arn = module.ecs_cl8.cluster_arn
  cpu         = 256
  memory      = 512

  create_tasks_iam_role     = false
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  enable_autoscaling        = false

  service_registries = {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  container_definitions = {
    redis = {
      essential = true
      image     = "767397659229.dkr.ecr.us-east-1.amazonaws.com/online-boutique/redis:7-alpine"

      portMappings = [
        {
          name          = "redis"
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true
    }
  }

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]
}