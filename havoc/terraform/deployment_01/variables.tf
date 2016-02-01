/*
  ======================================================
    'PROVIDER CONFIG'

    'These settings can be defaulted from your'
    '~/.aws/config and ~/.aws/credentials'.

  ======================================================
*/

provider "aws" {
  region = "${var.aws_region}"
}

/*
  ======================================================
    'AWS REGION, AZ and CIDR CONFIG'
  ======================================================
*/

variable "environment" {
  description = "Name your work!"
  default     = "HAVOC-DEV"
}

variable "aws_region" {
  description = "AWS REGION"
  default     = "us-east-1"
}

# TODO: find a way to call the present zones
variable "zones" {
  default = {
    "primary"   = "us-east-1b"
    "secondary" = "us-east-1c"
#    "tertiary"  = "us-east-1d"
  }
}

variable "vpc_cidrs" {
  default = {
    VPC   = "172.21.0.0/22"
    EXT1  = "172.21.0.0/24"
    INT1  = "172.21.1.0/24"
    EXT2  = "172.21.2.0/24"
    INT2  = "172.21.3.0/24"
  }
}

# in our app this is made with PACKER and placed in us-east-1
variable "aws_amis" {
  default = {
    us-east-1 = "ami-b2f6dad8"
  }
}


/*
  ======================================================
    'KEYPAIRS'
  ======================================================
*/


variable "public_key_path" {
  default     = "~/.ssh/id_rsa.pub"
  description = "SSH KEYPAIR"
}

variable "key_name" {
  default     = "havoc"
  description = "SSH KEYPAIR NAME"
}
