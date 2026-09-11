variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "my_ip" {
  type = string
}

variable "create_jenkins_sg" {
  description = "Whether to create the Jenkins security group"
  type        = bool
  default     = true
}