variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet for Jenkins"
  type        = string
}

variable "security_group_id" {
  description = "Jenkins Security Group"
  type        = string
}

variable "key_name" {
  description = "SSH Key Pair"
  type        = string
}

variable "instance_profile" {
  description = "IAM Instance Profile"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
}