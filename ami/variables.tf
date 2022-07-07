variable "region" {
  default = "sa-east-1"
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

variable "instance_type" {
  default = "t2.micro"
  type    = string
}
