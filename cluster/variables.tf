variable "region" {
  default = "sa-east-1"
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
  default = "t2.micro"
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

# variable "availability_zone_1" {
#   default = "sa-east-1a"
#   type    = string
# }

# variable "availability_zone_2" {
#   default = "sa-east-1b"
#   type    = string
# }

# variable "availability_zone_3" {
#   default = "sa-east-1c"
#   type    = string
# }

# variable "allowed_origin" {
#   default     = "0.0.0.0/0"
#   type        = string
#   description = "Use this variable to allow access only from your personal IP, if you choose so."
# }


