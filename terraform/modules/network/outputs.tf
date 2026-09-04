output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "vpc_cidr" {
  description = "CIDR of the VPC"
  value       = aws_vpc.this.cidr_block
}