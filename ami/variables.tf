variable "region" {
  default = "sa-east-1"
  type    = string
}

variable "project_name" {
  default = "ec2ha"
  type    = string
}

variable "availability_zone_1" {
  default = "sa-east-1a"
  type    = string
}

variable "availability_zone_2" {
  default = "sa-east-1b"
  type    = string
}

variable "availability_zone_3" {
  default = "sa-east-1c"
  type    = string
}

variable "allowed_origin" {
  default     = "0.0.0.0/0"
  type        = string
  description = "Use this variable to allow access only from your personal IP, if you choose so."
}
