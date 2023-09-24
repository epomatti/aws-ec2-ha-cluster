variable "region" {
  default = "us-east-2"
  type    = string
}

variable "project_name" {
  default = "ec2habase"
  type    = string
}

variable "allowed_origin" {
  default     = "0.0.0.0/0"
  type        = string
  description = "Use this variable to allow access only from your personal IP, if you choose so."
}

variable "ami" {
  default = "ami-0485ca4b2b7cb275d"
  type    = string
}

variable "instance_type" {
  default = "t4g.micro"
  type    = string
}
