variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block of the public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the public subnet"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}