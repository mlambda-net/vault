variable "aws_access_key_id" {
  description = "the aws access key id"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "the aws access secret key"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "the aws access region"
  type        = string
  default     = "us-east-1"
}

variable "email" {
  description = "the admin email"
  type = string
  default = ""
}

variable "domain" {
  description = "the domain site"
  type = string
  default = ""
}

variable "sub_domain" {
  description = "the sub domain site"
  type = string
  default = ""
}

# define a vpc
variable "vpc_cidr" {
  description = "the ip domain"
  type = string
  default = ""
}

# available zones
variable "availability_zone" {
  description = "availability zone used for the demo, based on region"
  default = {
    us-east-1 = "us-east-1a"
    us-west-1 = "us-west-1a"
  }
}

# public ip domain
variable "public_cidr" {
  description = "A list of public cidr inside the VPC"
  type        = string
  default     = ""
}

# public ip domain
variable "private_cidr" {
  description = "A list of public cidr inside the VPC"
  type        = string
  default     = ""
}

# the key name.
variable "key_name" {
  description = "the ssh key name"
  type        = string
  default     = ""
}
