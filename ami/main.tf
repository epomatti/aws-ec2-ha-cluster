terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21.0"
    }
  }
  backend "local" {
    path = "./.workspace/terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
}

### Locals ###

locals {
  affix      = var.project_name
  INADDR_ANY = "0.0.0.0/0"
}

### VPC ###
resource "aws_vpc" "base" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  # Enable DNS hostnames 
  enable_dns_hostnames = true

  tags = {
    Name = local.affix
  }
}

### Internet Gateway ###

resource "aws_internet_gateway" "base" {
  vpc_id = aws_vpc.base.id

  tags = {
    Name = "igw-${var.project_name}"
  }
}

### Route Tables ###

resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.base.default_route_table_id

  route {
    cidr_block = local.INADDR_ANY
    gateway_id = aws_internet_gateway.base.id
  }

  tags = {
    Name = "internet-rt"
  }
}

### Subnets ###

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.base.id
  cidr_block = "10.0.0.0/24"

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

### Security Group ###

# This will clean up all default entries
resource "aws_default_security_group" "base" {
  vpc_id = aws_vpc.base.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_origin]
  security_group_id = aws_default_security_group.base.id
}

# TODO: Add the Load balancer
resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_origin]
  security_group_id = aws_default_security_group.base.id
}

resource "aws_security_group_rule" "egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [local.INADDR_ANY]
  security_group_id = aws_default_security_group.base.id
}

resource "aws_security_group_rule" "egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [local.INADDR_ANY]
  security_group_id = aws_default_security_group.base.id
}

### IAM Role ###

resource "aws_iam_role" "base" {
  name = local.affix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
#   arn = "arn:aws:iam::aws:policy/AmazonEC2RoleforSSM"
# }

resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  role       = aws_iam_role.base.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

### Key Pair ###
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-base"
  public_key = file("${path.module}/id_rsa.pub")
}

### EC2 ###

resource "aws_network_interface" "base" {
  subnet_id       = aws_subnet.subnet.id
  security_groups = [aws_default_security_group.base.id]

  tags = {
    Name = "ni-${var.project_name}"
  }
}

resource "aws_iam_instance_profile" "base" {
  name = "${local.affix}-profile"
  role = aws_iam_role.base.id
}

resource "aws_instance" "base" {
  ami           = "ami-037c192f0fa52a358"
  instance_type = var.instance_type

  iam_instance_profile = aws_iam_instance_profile.base.id
  user_data            = file("${path.module}/user-data.sh")
  key_name             = aws_key_pair.deployer.key_name

  network_interface {
    network_interface_id = aws_network_interface.base.id
    device_index         = 0
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-baseimage"
  }
}
