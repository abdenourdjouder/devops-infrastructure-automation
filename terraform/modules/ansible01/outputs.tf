output "instance_id" {
  description = "ID of the ANSIBLE01 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address of ANSIBLE01"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of ANSIBLE01"
  value       = aws_instance.this.private_ip
}