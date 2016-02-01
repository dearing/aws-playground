
/*
  ======================================================
    'VIRTUAL PRIVATE CLOUD'
  ======================================================
*/

module "networking" {
  source = "../modules/networking"

  # Doesn't support complex variables here in the config yet.
  # So instead we convert everything to strings and pass it.

  environment  = "HAVOC-STG"

  # aws_region   = "us-east-1"
  # primary_az   = "us-east-1b"
  # secondary_az = "us-east-1c"

  # vpc_cidr   = "172.21.0.0/22"
  # ext1_cidr  = "172.21.0.0/24"
  # int1_cidr  = "172.21.1.0/24"
  # ext2_cidr  = "172.21.2.0/24"
  # int2_cidr  = "172.21.3.0/24"

}
