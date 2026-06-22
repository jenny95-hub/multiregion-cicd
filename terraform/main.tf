#################################################
# VPC MODULE
#################################################

module "vpc" {

  source = "./modules/vpc"

  project_name = var.project_name

  vpc_cidr = var.vpc_cidr

  azs = var.azs
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

  ami_id = data.aws_ami.ubuntu.id

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