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

### VPC Data Source ###
data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_security_group" "default" {
  id = var.security_group_id
}

### Launch Configuration ###

data "aws_iam_instance_profile" "default" {
  name = "${local.affix}-profile"
}

resource "aws_launch_configuration" "default" {
  name_prefix   = "launchconfig-${local.affix}"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile = data.aws_iam_instance_profile.default.name
  security_groups      = [data.aws_security_group.default.id]

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_autoscaling_group" "bar" {
#   name                 = "asg-${local.affix}"
#   launch_configuration = aws_launch_configuration.default.name
#   min_size             = var.asg_min_size
#   max_size             = var.asg_max_size

#   lifecycle {
#     create_before_destroy = true
#   }
# }
