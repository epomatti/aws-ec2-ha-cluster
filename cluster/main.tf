terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
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
  cidr_block        = "10.0.0.0/24"
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

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_origin]
  security_group_id = aws_default_security_group.default.id
}

resource "aws_security_group_rule" "egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [local.INADDR_ANY]
  security_group_id = aws_default_security_group.default.id
}

resource "aws_security_group_rule" "egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [local.INADDR_ANY]
  security_group_id = aws_default_security_group.default.id
}

### IAM Role ###

resource "aws_iam_role" "main" {
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
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

### Key Pair ###
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/../temp_rsa.pub")
}

### EC2 ###

resource "aws_network_interface" "main" {
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_default_security_group.default.id]

  tags = {
    Name = "ni-${var.project_name}"
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.affix}-profile"
  role = aws_iam_role.main.id
}

### Launch Configuration ###
resource "aws_launch_template" "foo" {
  name                   = "launchtemplate-${local.affix}"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  image_id               = var.ami_id
  vpc_security_group_ids = [aws_default_security_group.default.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      encrypted  = true
      kms_key_id = var.kms_key_arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }
}

### ALB ###
resource "aws_security_group" "allow_http_lb" {
  name        = "Allow HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.INADDR_ANY]
  }

  egress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.INADDR_ANY]
  }

  tags = {
    Name = "lb-sc"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "tg-${local.affix}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_autoscaling_group" "default" {
  name = "asg-${local.affix}"

  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    name = aws_launch_template.foo.name
  }

  depends_on = [aws_kms_key_policy.autoscaling]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = "${local.affix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_lb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

### Allow EC2 autoscaling  to use encrypted volumes ###

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_kms_key_policy" "autoscaling" {
  key_id = var.kms_key_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowEC2"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${local.aws_account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow service-linked role use of the customer managed key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:CreateGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : true
          }
        }
      }
    ]
  })
}
