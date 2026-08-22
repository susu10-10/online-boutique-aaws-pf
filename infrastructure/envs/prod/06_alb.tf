module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0.0"

  name               = "${var.project_name}-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"

  security_groups = [module.alb_sg.security_group_id]

  enable_deletion_protection = false


  target_groups = {
    frontend_tg = {
      name_prefix = "fe-"
      protocol    = "HTTP"
      port        = 8080
      target_type = "ip"

      health_check = {
        enabled             = true
        path                = "/_healthz"
        port                = "8080"
        matcher             = "200"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }
      create_attachment = false
    }
  }


  listeners = {
    # Redirect all Port 80 traffic to Port 443

    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    # Terminate TLS and forward to the Fargate Container
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn

      forward = {
        target_group_key = "frontend_tg"
      }
    }
  }

  tags = var.tags
}

output "alb_dns_name" {
  description = "The public DNS name of the load balancer"
  value       = module.alb.dns_name
}