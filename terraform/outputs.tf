output "ansible01_instance_id" {
  description = "ID of the ANSIBLE01 EC2 instance"
  value       = module.ansible01.instance_id
}

output "ansible01_public_ip" {
  description = "Public IP address of ANSIBLE01"
  value       = module.ansible01.public_ip
}

output "ansible01_private_ip" {
  description = "Private IP address of ANSIBLE01"
  value       = module.ansible01.private_ip
}

output "vpc_id" {
  description = "ID of the lab VPC"
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "ID of the lab public subnet"
  value       = module.network.subnet_id
}

output "security_group_id" {
  description = "ID of the lab security group"
  value       = module.security.security_group_id
}