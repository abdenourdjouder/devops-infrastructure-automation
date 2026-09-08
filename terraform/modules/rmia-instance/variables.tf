variable "name" {
  description = "Name of the RMIA Windows instance"
  type        = string
}

variable "ami_id" {
  description = "Windows Server AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the RMIA instance will be created"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the RMIA instance"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "role" {
  description = "Role of the Windows server"
  type        = string
  default     = "rmia-windows"
}
