output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}

output "jenkins_instance_id" {
  value = module.jenkins.jenkins_instance_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  value = module.ecs.task_definition_arn
}

output "secondary_vpc_id" {
  description = "Secondary region VPC ID"
  value       = module.vpc_secondary.vpc_id
}

output "secondary_public_subnet_ids" {
  description = "Secondary region public subnet IDs"
  value       = module.vpc_secondary.public_subnet_ids
}

output "secondary_private_subnet_ids" {
  description = "Secondary region private subnet IDs"
  value       = module.vpc_secondary.private_subnets_ids
}

output "secondary_alb_sg_id" {
  description = "ALB security group in secondary region"
  value       = module.security_secondary.alb_sg_id
}

output "secondary_ecs_sg_id" {
  description = "ECS security group in secondary region"
  value       = module.security_secondary.ecs_sg_id
}

output "secondary_alb_dns_name" {
  value = module.alb_secondary.alb_dns_name
}

output "secondary_alb_arn" {
  value = module.alb_secondary.alb_arn
}

output "secondary_blue_target_group_arn" {
  value = module.alb_secondary.blue_target_group_arn
}

output "secondary_green_target_group_arn" {
  value = module.alb_secondary.green_target_group_arn
}

output "secondary_production_listener_arn" {
  value = module.alb_secondary.production_listener_arn
}

output "secondary_test_listener_arn" {
  value = module.alb_secondary.test_listener_arn
}

output "secondary_ecr_repository_url" {
  description = "ECR repository URL in the secondary region"
  value       = module.ecr_secondary.repository_url
}

output "secondary_ecr_repository_name" {
  description = "ECR repository name in the secondary region"
  value       = module.ecr_secondary.repository_name
}

output "secondary_codedeploy_app_name" {
  value = module.codedeploy_secondary.codedeploy_app_name
}

output "secondary_codedeploy_deployment_group_name" {
  value = module.codedeploy_secondary.codedeploy_deployment_group_name
}

output "route53_zone_id" {
  value = module.route53.zone_id
}

output "route53_name_servers" {
  value = module.route53.name_servers
}