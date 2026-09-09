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

  rmia01_private_ip = module.rmia01.private_ip
  rmia02_private_ip = module.rmia02.private_ip
}

module "rmia" {
  source = "./modules/rmia"

  vpc_id = module.network.vpc_id

  ansible_security_group_id = module.security.security_group_id

  environment = "devops-lab"
}

resource "aws_key_pair" "rmia" {
  key_name   = "devops-lab-rmia-admin"
  public_key = file(pathexpand("~/.ssh/rmia.pub"))

  tags = {
    Name        = "devops-lab-rmia-admin"
    Environment = "devops-lab"
    Role        = "rmia-windows-admin"
  }
}

module "rmia01" {
  source = "./modules/rmia-instance"

  name              = "RMIA01"
  ami_id            = "ami-040a155879de85e73"
  instance_type     = "t3.small"
  subnet_id         = module.network.subnet_id
  security_group_id = module.rmia.security_group_id
  key_name          = aws_key_pair.rmia.key_name
  environment       = "devops-lab"
  role              = "rmia-tomcat7"

}

module "rmia02" {
  source = "./modules/rmia-instance"

  name              = "RMIA02"
  ami_id            = "ami-040a155879de85e73"
  instance_type     = "t3.small"
  subnet_id         = module.network.subnet_id
  security_group_id = module.rmia.security_group_id
  key_name          = aws_key_pair.rmia.key_name
  environment       = "devops-lab"
  role              = "rmia-tomcat9"

}
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/generated/hosts"

  content = templatefile(
    "${path.module}/inventory.tftpl",
    {
      rmia01_private_ip = module.rmia01.private_ip
      rmia02_private_ip = module.rmia02.private_ip
    }
  )
}

resource "null_resource" "ansible_inventory_sync" {
  triggers = {
    inventory = local_file.ansible_inventory.content
  }

  connection {
    type        = "ssh"
    host        = module.ansible01.public_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/ansible01"))
  }

  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ansible/inventory",
      "sudo cp /tmp/hosts /etc/ansible/inventory/hosts",
      "sudo chown root:root /etc/ansible/inventory/hosts",
      "sudo chmod 644 /etc/ansible/inventory/hosts"
    ]
  }
}
resource "null_resource" "ansible_secrets_bootstrap" {
  triggers = {
    ansible01_instance_id = module.ansible01.instance_id
    rmia01_instance_id    = module.rmia01.instance_id
    rmia02_instance_id    = module.rmia02.instance_id
  }

  depends_on = [
    null_resource.ansible_inventory_sync
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT
      & "${path.module}/scripts/bootstrap-ansible-secrets.ps1" `
        -AnsiblePublicIp "${module.ansible01.public_ip}" `
        -Rmia01InstanceId "${module.rmia01.instance_id}" `
        -Rmia02InstanceId "${module.rmia02.instance_id}"
    EOT
  }
}