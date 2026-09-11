output "jenkins_sg_id" {
  value = var.create_jenkins_sg ? aws_security_group.jenkins_sg[0].id : null
}

output "alb_sg_id" {
  value = aws_security_group.alb-sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs-sg.id
}