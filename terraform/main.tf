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