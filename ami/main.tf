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
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  # Enable DNS hostnames 
  enable_dns_hostnames = true

  tags = {
    Name = local.affix
  }
}

### Internet Gateway ###

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}"
  }
}

### Route Tables ###

resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = local.INADDR_ANY
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "internet-rt"
  }
}

### Subnets ###

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.availability_zone_1

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = var.availability_zone_2

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = var.availability_zone_3

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet3"
  }
}

### Security Group ###

# This will clean up all default entries
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_origin]
  security_group_id = aws_default_security_group.default.id
}

# TODO: Add the Load balancer
resource "aws_security_group_rule" "ingres_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_origin]
  security_group_id = aws_default_security_group.default.id
}

### IAM Role ###

resource "aws_iam_role" "default" {
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

resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  role       = aws_iam_role.default.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

### Key Pair ###
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/id_rsa.pub")
}

### EC2 ###

resource "aws_network_interface" "default" {
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_default_security_group.default.id]

  tags = {
    Name = "ni-${var.project_name}"
  }
}

resource "aws_iam_instance_profile" "default" {
  name = "${local.affix}-profile"
  role = aws_iam_role.default.id
}

resource "aws_instance" "default" {
  ami           = "ami-037c192f0fa52a358"
  instance_type = var.instance_type

  availability_zone    = var.availability_zone_1
  iam_instance_profile = aws_iam_instance_profile.default.id
  user_data            = file("${path.module}/user-data.sh")
  key_name             = aws_key_pair.deployer.key_name

  network_interface {
    network_interface_id = aws_network_interface.default.id
    device_index         = 0
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "ec2-${var.project_name}"
  }
}
