variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets used by ECS Fargate tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group attached to ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 5000
}

variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
  default     = 2
}