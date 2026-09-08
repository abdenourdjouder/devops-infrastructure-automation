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
output "rmia01_instance_id" {
  description = "ID of RMIA01"
  value       = module.rmia01.instance_id
}

output "rmia01_private_ip" {
  description = "Private IP address of RMIA01"
  value       = module.rmia01.private_ip
}

output "rmia01_public_ip" {
  description = "Public IP address of RMIA01"
  value       = module.rmia01.public_ip
}

output "rmia02_instance_id" {
  description = "ID of RMIA02"
  value       = module.rmia02.instance_id
}

output "rmia02_private_ip" {
  description = "Private IP address of RMIA02"
  value       = module.rmia02.private_ip
}

output "rmia02_public_ip" {
  description = "Public IP address of RMIA02"
  value       = module.rmia02.public_ip
}

output "rmia_security_group_id" {
  description = "ID of the RMIA security group"
  value       = module.rmia.security_group_id
}