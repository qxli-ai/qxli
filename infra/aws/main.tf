terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  selected_ami = var.ami_id
  name_prefix  = "${terraform.workspace}-${var.product_name}"
  key_name     = "${local.name_prefix}-${var.key_pair_name}"
}

resource "aws_key_pair" "qxli" {
  key_name   = local.key_name
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "qxli" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for QXLI single-node stack"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidrs
  }

  # App ports (adjust as needed)
  dynamic "ingress" {
    for_each = var.allowed_app_ports
    content {
      description = "App port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_instance" "qxli" {
  ami                         = local.selected_ami
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  key_name                    = aws_key_pair.qxli.key_name
  vpc_security_group_ids      = [aws_security_group.qxli.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release

              # Docker
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Add ubuntu user to docker group
              usermod -aG docker ubuntu || true
              systemctl enable docker
              systemctl start docker
              EOF

  tags = {
    Name    = "${local.name_prefix}-instance"
    Project = var.project
  }
}

# Elastic IP for static public IP
resource "aws_eip" "qxli" {
  domain = "vpc"

  tags = {
    Name    = "${local.name_prefix}-eip"
    Project = var.project
  }
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "qxli" {
  instance_id   = aws_instance.qxli.id
  allocation_id = aws_eip.qxli.id
}
