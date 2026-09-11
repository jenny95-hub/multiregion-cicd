#################################################
# VPC MODULE
#################################################

module "vpc" {

  source = "./modules/vpc"

  project_name = var.project_name

  vpc_cidr = var.vpc_cidr

  azs = var.azs

  enable_nat_gateway = var.enable_nat_gateway
}


#################################################
# SECURITY GROUP MODULE
#################################################

module "security" {

  source = "./modules/security-groups"

  project_name = var.project_name

  vpc_id = module.vpc.vpc_id

  my_ip = var.my_ip
}

#################################################
# IAM MODULE
#################################################

module "iam" {

  source = "./modules/iam"

  project_name = var.project_name
}

#################################################
# JENKINS MODULE
#################################################

module "jenkins" {

  source = "./modules/jenkins"

  project_name = var.project_name

  ami_id = var.jenkins_ami_id

  instance_type = var.jenkins_instance_type

  subnet_id = module.vpc.public_subnet_ids[0]

  security_group_id = module.security.jenkins_sg_id

  instance_profile = module.iam.jenkins_instance_profile

  key_name = var.key_name
}

module "ecr" {

  source = "./modules/ecr"

  project_name = var.project_name
}

#################################################
# ALB MODULE
#################################################

module "alb" {

  source = "./modules/alb"

  project_name = var.project_name

  vpc_id = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnet_ids

  alb_security_group_id = module.security.alb_sg_id

  container_port = 5000
}

#################################################
# ECS MODULE
#################################################

module "ecs" {

  source = "./modules/ecs"

  project_name = var.project_name

  aws_region = var.aws_region

  ecr_repository_url = module.ecr.repository_url

  subnet_ids = module.vpc.public_subnet_ids

  ecs_security_group_id = module.security.ecs_sg_id

  target_group_arn = module.alb.blue_target_group_arn

  container_port = 5000

  desired_count = 2
}


module "codedeploy" {
  source = "./modules/codedeploy"

  project_name = var.project_name

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  blue_target_group_name  = module.alb.blue_target_group_name
  green_target_group_name = module.alb.green_target_group_name

  production_listener_arn = module.alb.production_listener_arn
  test_listener_arn       = module.alb.test_listener_arn
}


module "vpc_secondary" {
  source = "./modules/vpc"

  providers = {
    aws = aws.secondary
  }

  project_name       = "${var.project_name}-secondary"
  vpc_cidr           = var.secondary_vpc_cidr
  azs                = var.secondary_azs
  enable_nat_gateway = false
}

module "security_secondary" {
  source = "./modules/security-groups"

  providers = {
    aws = aws.secondary
  }

  project_name      = "${var.project_name}-secondary"
  vpc_id            = module.vpc_secondary.vpc_id
  my_ip             = var.my_ip
  create_jenkins_sg = false
}

module "alb_secondary" {
  source = "./modules/alb"

  providers = {
    aws = aws.secondary
  }

  project_name          = "${var.project_name}-secondary"
  resource_name         = "mr-cicd-secondary"
  vpc_id                = module.vpc_secondary.vpc_id
  public_subnet_ids     = module.vpc_secondary.public_subnet_ids
  alb_security_group_id = module.security_secondary.alb_sg_id
  container_port        = 5000
}

module "ecr_secondary" {
  source = "./modules/ecr"

  providers = {
    aws = aws.secondary
  }

  project_name = var.project_name
}

module "ecs_secondary" {
  source = "./modules/ecs"

  providers = {
    aws = aws.secondary
  }

  project_name = "${var.project_name}-secondary"
  aws_region   = var.secondary_aws_region

  subnet_ids = module.vpc_secondary.public_subnet_ids

  ecs_security_group_id = module.security_secondary.ecs_sg_id

  target_group_arn = module.alb_secondary.blue_target_group_arn

  ecr_repository_url = module.ecr_secondary.repository_url

  container_port = 5000
  desired_count  = 0
}

module "codedeploy_secondary" {
  source = "./modules/codedeploy"

  providers = {
    aws = aws.secondary
  }

  project_name = "${var.project_name}-secondary"

  ecs_cluster_name = module.ecs_secondary.cluster_name
  ecs_service_name = module.ecs_secondary.service_name

  blue_target_group_name  = "mr-cicd-secondary-tg"
  green_target_group_name = "mr-cicd-secondary-green-tg"

  production_listener_arn = module.alb_secondary.production_listener_arn
  test_listener_arn       = module.alb_secondary.test_listener_arn
}

module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  domain_name  = "cloudopslab.infotechnology.com"
}