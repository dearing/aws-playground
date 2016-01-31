# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "jaco7316"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-de7ab6b6"
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