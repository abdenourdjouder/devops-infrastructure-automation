variable "subnet_id" {
  description = "ID of the subnet where ANSIBLE01 will be created"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for ANSIBLE01"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for ANSIBLE01"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
variable "public_key" {
  description = "SSH public key for administrative access to ANSIBLE01"
  type        = string
}