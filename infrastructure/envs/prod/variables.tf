variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "online-boutique"
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "online-boutique-AWS"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "domain_name" {
  description = "The custom domain name for the portfolio"
  type        = string
  default     = "suworks.me"
}