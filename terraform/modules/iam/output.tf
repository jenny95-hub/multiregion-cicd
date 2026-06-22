output "jenkins_instance_profile" {
  value = aws_iam_instance_profile.jenkins_profile.name
}