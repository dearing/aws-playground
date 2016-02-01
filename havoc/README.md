[havoc] experiments
===
experiments with deployment (AWS)

on [terraform]
-----
Terraform promises better interop with teams than cloud formation.  Let's dive in.

![current graph!](terraform/graph.png?raw=true)

Terraform is a nice tool from [hasicorp] for describing a provider as state.  You can plan and apply by a state while sharing it with other members of your team.  The configuration for resources are in hashicorp's configuration language, [hcl], and compared to writing cloudformation templates, much easier. Think human-usable JSON with string interpolation and comments.  If your a fan of sublimetext3, there is a [terraform plugin].  As a taste, here is setting up a nat gateway with route tables and association.

```tf
/*
  ======================================================
    'NAT Gatways and Routes'
  ======================================================
*/


# EIP and NAT GATEWAY for SUBNET EXT/INT 01
resource "aws_eip" "nat1" {
  vpc = true
}
resource "aws_nat_gateway" "nat1" {
  allocation_id = "${aws_eip.nat1.id}"
  subnet_id     = "${aws_subnet.ext1.id}"
  depends_on    = ["aws_internet_gateway.default"]
}
# ROUTE all to NAT GATEWAY 01
resource "aws_route_table" "nat1rt" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat1.id}"
  }
  tags {
    Name = "NAT1-ROUTING"
  }
}
# ASSOCIATE our ROUTE TABLE to the INTERNAL SUBNET 01
resource "aws_route_table_association" "nat1rta" {
  subnet_id = "${aws_subnet.int1.id}"
  route_table_id = "${aws_route_table.nat1rt.id}"
}

```


One of the nicest things about using it is that all of the `.tf` configs are mashed together, not nested, making working with them a breeze and `organize-by-file` a thing.  Terraform further allows for modules, which are re-usable components that are organized with simple directories and mapped with a config.

`more later...`

[havoc]: https://github.com/dearing/havoc_server
[hasicorp]: https://www.hashicorp.com/
[hcl]: https://github.com/hashicorp/hcl
[terraform]: https://www.terraform.io/
[terraform plugin]: https://packagecontrol.io/packages/Terraform
