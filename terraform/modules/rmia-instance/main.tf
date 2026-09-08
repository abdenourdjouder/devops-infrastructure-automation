resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

user_data = file("${path.module}/userdata.yml")

  tags = {
    Name        = var.name
    Environment = var.environment
    Role        = var.role
  }
}