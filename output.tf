output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}

output "jenkins_instance_id" {
  value = module.jenkins.jenkins_instance_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}