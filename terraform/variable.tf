variable "aws_region" {
  description = "Primary region"
  type        = string
  default     = "ap-south-1"
}

variable "secondary_aws_region" {
  description = "Secondary region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "my_ip" {
  description = "Your public IP with /32"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair"
  type        = string
}

variable "jenkins_instance_type" {
  description = "Jenkins EC2 type"
  type        = string
}

variable "jenkins_ami_id" {
  description = "Pinned AMI used by the Jenkins EC2 instance"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary region VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "secondary_azs" {
  description = "Availability zones for secondary region"
  type        = list(string)

  default = [
    "ap-southeast-1a",
    "ap-southeast-1b"
  ]
}