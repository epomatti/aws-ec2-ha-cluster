variable "region" {
  default = "us-east-2"
  type    = string
}

variable "project_name" {
  default = "ec2ha"
  type    = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  default = "t4g.micro"
  type    = string
}

variable "asg_min_size" {
  default = 1
  type    = number
}

variable "asg_max_size" {
  default = 1
  type    = number
}

variable "asg_desired_capacity" {
  default = 1
  type    = number
}

variable "availability_zone_1" {
  default = "us-east-2a"
  type    = string
}

variable "availability_zone_2" {
  default = "us-east-2b"
  type    = string
}

variable "availability_zone_3" {
  default = "us-east-2c"
  type    = string
}

variable "allowed_origin" {
  default     = "0.0.0.0/0"
  type        = string
  description = "Use this variable to allow access only from your personal IP, if you choose so."
}


