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

module "network" {
  source = "./modules/network"

  vpc_cidr          = "172.20.0.0/16"
  subnet_cidr       = "172.20.1.0/24"
  availability_zone = "us-east-1a"
  environment       = "devops-lab"
}
module "security" {
  source = "./modules/security"

  vpc_id      = module.network.vpc_id
  environment = "devops-lab"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "ansible01" {
  source = "./modules/ansible01"

  subnet_id         = module.network.subnet_id
  security_group_id = module.security.security_group_id

  instance_type = "t3.small"
  ami_id        = data.aws_ami.ubuntu.id
  environment   = "devops-lab"

  public_key = file(pathexpand("~/.ssh/ansible01.pub"))
}