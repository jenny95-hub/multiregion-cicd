output "jenkins_sg_id" {
  value = aws_security_group.jenkins_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb-sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs-sg.id
}