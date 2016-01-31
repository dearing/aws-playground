# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

variable "public_key_path" {
  default     = "~/.ssh/id_rsa.pub"
  description = "SSH KEYPAIR"
}

variable "key_name" {
  description = "SSH KEYPAIR NAME"
  default     = "jaco7316"
}

variable "aws_region" {
  description = "AWS REGION"
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-5715393d"
  }
}

variable "vpc_cidrs" {
  default = {
    vpc   = "172.21.0.0/22"
    ext-1 = "172.21.0.0/24"
    int-1 = "172.21.1.0/24"
    ext-2 = "172.21.2.0/24"
    int-2 = "172.21.3.0/24"
  }
}
variable "zones" {
  default = {
    "primary"   = "us-east-1b"
    "secondary" = "us-east-1c"
    "tertiary"  = "us-east-1d"
  }
}