variable "vpc_id" {
  description = "ID of the VPC where the RMIA security group will be created"
  type        = string
}

variable "ansible_security_group_id" {
  description = "Security group ID of ANSIBLE01 allowed to access RMIA servers"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}