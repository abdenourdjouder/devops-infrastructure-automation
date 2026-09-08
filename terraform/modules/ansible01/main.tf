resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.this.key_name
  
  user_data = templatefile("${path.module}/bootstrap.sh", {
  rmia01_private_ip = var.rmia01_private_ip
  rmia02_private_ip = var.rmia02_private_ip
  })
  
  tags = {
    Name        = "ANSIBLE01"
    Environment = var.environment
    Role        = "ansible-control-node"
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.environment}-ansible01-admin"
  public_key = var.public_key

  tags = {
    Name        = "${var.environment}-ansible01-admin"
    Environment = var.environment
    Role        = "ansible-control-node"
  }
}