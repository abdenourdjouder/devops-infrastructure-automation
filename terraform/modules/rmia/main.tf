resource "aws_security_group" "this" {
  name        = "${var.environment}-rmia-sg"
  description = "Security group for RMIA Windows servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "WinRM HTTPS from ANSIBLE01"
    from_port       = 5986
    to_port         = 5986
    protocol        = "tcp"
    security_groups = [var.ansible_security_group_id]
  }
  ingress {
    description = "Temporary RDP access for initial Windows configuration"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rmia-sg"
    Environment = var.environment
    Role        = "rmia-windows"
  }
}