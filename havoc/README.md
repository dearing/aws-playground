[havoc] experiments
===
experiments with deployment (AWS)

of [terraform]
-----
Terraform promises better interop with teams than cloud formation.  Let's dive in.

![current graph!](terraform/graph.png?raw=true)

Terraform is a nice tool from [hasicorp] for describing a provider as state.  You can plan and apply by a state while sharing it with other members of your team.  The configuration for resources are in hashicorp's configuration language, [hcl].  Think human-usable JSON with string interpolation and comments.  The learning curve is slow and if your a fan of sublimetext3, there is a [terraform plugin].

```
# ROUTE all to NAT GATEWAY 02
resource "aws_route_table" "nat2rt" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat2.id}"
  }
  tags {
    Name = "NAT2-ROUTING"
  }
}
```
One of the nicest things about using it is that all of the `.tf` configs are mashed together, not nested, making working with them a breeze and `organize-by-file` availiable.  Terraform further allows for modules, which are re-usable components that are organized with simple directories and mapped with a config.

`more later...`

[havoc]: https://github.com/dearing/havoc_server
[hasicorp]: https://www.hashicorp.com/
[hcl]: https://github.com/hashicorp/hcl
[terraform]: https://www.terraform.io/
[terraform plugin]: https://packagecontrol.io/packages/Terraform
