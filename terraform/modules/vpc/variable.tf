variable "vpc_cidr" {
  description = "CIDR block for vpc"
  type        = string
}

variable "project_name" {
  description = "project name used for tagging"
  type        = string
}

variable "azs" {
  description = "availability zones"
  type        = list(string)
}