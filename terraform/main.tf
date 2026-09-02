terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "kodekloud"
}

resource "aws_instance" "windows_lab" {
  ami           = "ami-040a155879de85e73"
  instance_type = "t3.small"

  subnet_id = "subnet-0ee71acd17598ff28"

  vpc_security_group_ids = [
    "sg-0d0d56d81124af0c3",
  ]

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "ANSIBLE01"
  }
}