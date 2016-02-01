/*
  ======================================================
    'AWS REGION, AZ and CIDR CONFIG'
  ======================================================
*/


provider "aws" {
  region = "${var.aws_region}"
}

variable "environment" {
  description = "name your work"
  default     = "DEV"
}

variable "aws_region" {
  description = "AWS REGION"
  default     = "us-east-1"
}


variable "primary_az" {
  description = "primary availability zone"
  default     = "us-east-1b"
}

variable "secondary_az" {
  description = "secondary availability zone"
  default     = "us-east-1c"
}


variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "172.21.0.0/22"
}

variable "ext1_cidr" {
  description = "primary external subnet CIDR"
  default     = "172.21.0.0/24"
}

variable "int1_cidr" {
  description = "primary internal subnet CIDR"
  default     = "172.21.1.0/24"
}

variable "ext2_cidr" {
  description = "secondary external subnet CIDR"
  default     = "172.21.2.0/24"
}

variable "int2_cidr" {
  description = "secondary internal subnet CIDR"
  default     = "172.21.3.0/24"
}
