output "instance_id" {
  description = "ID of the RMIA Windows instance"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address of the RMIA Windows instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the RMIA Windows instance"
  value       = aws_instance.this.public_ip
}