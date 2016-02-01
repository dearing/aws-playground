[havoc] experiments
===
experiments with deployment (AWS) *evolving doc*

on [terraform]
-----
Terraform promises better interop with teams than cloud formation.  Let's dive in with a graph of the deployment thus far:
```
# terraform graph | dot -Tpng > graph.png
```

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
*note that we get github syntax highlighting for `.tf`*:thumbsup:


The generated state file for that bit of code is just JSON and looks something like this from a real deployment:

```json
"aws_route_table.nat2rt": {
    "type": "aws_route_table",
    "depends_on": [
        "aws_nat_gateway.nat2",
        "aws_vpc.default"
    ],
    "primary": {
        "id": "rtb-6e373b0a",
        "attributes": {
            "id": "rtb-6e373b0a",
            "propagating_vgws.#": "0",
            "route.#": "1",
            "route.2210866282.cidr_block": "0.0.0.0/0",
            "route.2210866282.gateway_id": "",
            "route.2210866282.instance_id": "",
            "route.2210866282.nat_gateway_id": "nat-0d1707e8dec27c564",
            "route.2210866282.network_interface_id": "",
            "route.2210866282.vpc_peering_connection_id": "",
            "tags.#": "1",
            "tags.Name": "NAT2-ROUTING",
            "vpc_id": "vpc-c286c5a6"
        }
    }
},
"aws_route_table_association.nat1rta": {
    "type": "aws_route_table_association",
    "depends_on": [
        "aws_route_table.nat1rt",
        "aws_subnet.int1"
    ],
    "primary": {
        "id": "rtbassoc-8bfb73ec",
        "attributes": {
            "id": "rtbassoc-8bfb73ec",
            "route_table_id": "rtb-6d373b09",
            "subnet_id": "subnet-bed21694"
        }
    }
},
"aws_route_table_association.nat2rta": {
    "type": "aws_route_table_association",
    "depends_on": [
        "aws_route_table.nat2rt",
        "aws_subnet.int2"
    ],
    "primary": {
        "id": "rtbassoc-8cfb73eb",
        "attributes": {
            "id": "rtbassoc-8cfb73eb",
            "route_table_id": "rtb-6e373b0a",
            "subnet_id": "subnet-1ca4126a"
        }
    }
}
```

One of the nicest things about using it is that all of the `.tf` configs are mashed together, not nested, making working with them a breeze and `organize-by-file` a thing.  Terraform further allows for modules, which are re-usable components that are organized with simple directories and mapped with a config.

Let's see what `terraform plan` out put looks like while also introducing some of the flexibility of the HCL here.  We will add a new var `environment` and then use the string formatter (golang templating for the win!) to create dynamic tags.  Here is our diff:

```diff
diff --git a/havoc/terraform/deployment_01/application.tf b/havoc/terraform/deployment_01/application.tf
index d5a5e8b..509fc32 100644
--- a/havoc/terraform/deployment_01/application.tf
+++ b/havoc/terraform/deployment_01/application.tf
@@ -26,7 +26,7 @@ resource "aws_security_group" "elb" {
   }
 
   tags {
-    Name = "HAVOC-SG-ELB"
+    Name = "${upper(format("%s-ELB-SG", var.environment))}"
   }
 }
 
@@ -60,7 +60,7 @@ resource "aws_security_group" "ec2" {
   }
 
   tags {
-    Name = "HAVOC-SG-EC2"
+    Name = "${upper(format("%s-EC2-SG", var.environment))}"
   }
 }
 
@@ -98,7 +98,7 @@ resource "aws_elb" "default" {
   }
 
   tags {
-    Name = "HAVOC-ELB"
+    Name = "${upper(format("%s-ELB", var.environment))}"
   }
 }
 
@@ -145,7 +145,7 @@ resource "aws_autoscaling_group" "default" {
 
   tag {
     key = "Name"
-    value = "HAVOC-DEV"
+    value = "${upper(format("%s-ASG", var.environment))}"
     propagate_at_launch = true
   }
 }
diff --git a/havoc/terraform/deployment_01/networking.tf b/havoc/terraform/deployment_01/networking.tf
index 3491541..b3104dc 100644
--- a/havoc/terraform/deployment_01/networking.tf
+++ b/havoc/terraform/deployment_01/networking.tf
@@ -7,7 +7,7 @@
 resource "aws_vpc" "default" {
   cidr_block = "${lookup(var.vpc_cidrs, "VPC")}"
   tags {
-    Name = "HAVOC-DEV"
+    Name = "${upper(format("%s-VPC", var.environment))}"
   }
 }
 
@@ -24,7 +24,7 @@ resource "aws_subnet" "ext1" {
   availability_zone       = "${lookup(var.zones, "primary")}"
   map_public_ip_on_launch = true
   tags {
-    Name = "EXT1"
+    Name = "${upper(format("%s-EXT1", var.environment))}"
   }
 }
 # SUBNET INTERNAL 01
@@ -34,7 +34,7 @@ resource "aws_subnet" "int1" {
   availability_zone       = "${aws_subnet.ext1.availability_zone}"
   map_public_ip_on_launch = false
   tags {
-    Name = "INT1"
+    Name = "${upper(format("%s-INT1", var.environment))}"
   }
 }
 
@@ -52,7 +52,7 @@ resource "aws_subnet" "ext2" {
   availability_zone       = "${lookup(var.zones, "secondary")}"  
   map_public_ip_on_launch = true
   tags {
-    Name = "EXT2"
+    Name = "${upper(format("%s-EXT2", var.environment))}"
   }
 }
 # SUBNET INTERNAL 02
@@ -62,7 +62,7 @@ resource "aws_subnet" "int2" {
   availability_zone       = "${aws_subnet.ext2.availability_zone}"
   map_public_ip_on_launch = false
   tags {
-    Name = "INT2"
+    Name = "${upper(format("%s-INT2", var.environment))}"
   }
 }
 
@@ -77,7 +77,7 @@ resource "aws_subnet" "int2" {
 resource "aws_internet_gateway" "default" {
   vpc_id = "${aws_vpc.default.id}"
   tags {
-    Name = "HAVOC-DEV-IG"
+    Name = "${upper(format("%s-IG", var.environment))}"
   }
 }
 
@@ -112,7 +112,7 @@ resource "aws_route_table" "nat1rt" {
     nat_gateway_id = "${aws_nat_gateway.nat1.id}"
   }
   tags {
-    Name = "NAT1-ROUTING"
+    Name = "${upper(format("%s-NAT1-RT", var.environment))}"
   }
 }
 # ASSOCIATE our ROUTE TABLE to the INTERNAL SUBNET 01
@@ -140,7 +140,7 @@ resource "aws_route_table" "nat2rt" {
     nat_gateway_id = "${aws_nat_gateway.nat2.id}"
   }
   tags {
-    Name = "NAT2-ROUTING"
+    Name = "${upper(format("%s-NAT2-RT", var.environment))}"
   }
 }
 # ASSOCIATE our ROUTE TABLE to the INTERNAL SUBNET 02
diff --git a/havoc/terraform/deployment_01/variables.tf b/havoc/terraform/deployment_01/variables.tf
index 200f959..d0467a8 100644
--- a/havoc/terraform/deployment_01/variables.tf
+++ b/havoc/terraform/deployment_01/variables.tf
@@ -18,6 +18,11 @@ provider "aws" {
   ======================================================
 */
 
+variable "environment" {
+  description = "Name your work!"
+  default     = "HAVOC-DEV"
+}
+
 variable "aws_region" {
   description = "AWS REGION"
   default     = "us-east-1"

```

Finally, we run `terraform plan` and see what changes the tool would do with our new work.

```
# terraform plan
~ aws_autoscaling_group.default
    tag.1637732627.key:                 "" => "Name"
    tag.1637732627.propagate_at_launch: "" => "1"
    tag.1637732627.value:               "" => "HAVOC-DEV-ASG"
    tag.244279944.key:                  "Name" => ""
    tag.244279944.propagate_at_launch:  "1" => "0"
    tag.244279944.value:                "HAVOC-DEV" => ""

~ aws_elb.default
    tags.Name: "HAVOC-ELB" => "HAVOC-DEV-ELB"

~ aws_route_table.nat1rt
    tags.Name: "NAT1-ROUTING" => "HAVOC-DEV-NAT1-RT"

~ aws_route_table.nat2rt
    tags.Name: "NAT2-ROUTING" => "HAVOC-DEV-NAT2-RT"

~ aws_security_group.ec2
    tags.Name: "HAVOC-SG-EC2" => "HAVOC-DEV-EC2-SG"

~ aws_security_group.elb
    tags.Name: "HAVOC-SG-ELB" => "HAVOC-DEV-ELB-SG"

~ aws_subnet.ext1
    tags.Name: "EXT1" => "HAVOC-DEV-EXT1"

~ aws_subnet.ext2
    tags.Name: "EXT2" => "HAVOC-DEV-EXT2"

~ aws_subnet.int1
    tags.Name: "INT1" => "HAVOC-DEV-INT1"

~ aws_subnet.int2
    tags.Name: "INT2" => "HAVOC-DEV-INT2"

~ aws_vpc.default
    tags.Name: "HAVOC-DEV" => "HAVOC-DEV-VPC"
```

Looking good.  This effectively demonstrates a tight `check your work as you go` model that I enjoy.  Something I miss from working with CFORM.   Lets push this up:

```
# terraform apply
aws_eip.nat2: Refreshing state... (ID: eipalloc-eae69d8e)
aws_vpc.default: Refreshing state... (ID: vpc-c286c5a6)
aws_key_pair.default: Refreshing state... (ID: havoc)
aws_eip.nat1: Refreshing state... (ID: eipalloc-bbe19adf)
aws_subnet.ext1: Refreshing state... (ID: subnet-b8d21692)
aws_internet_gateway.default: Refreshing state... (ID: igw-83468ee7)
aws_security_group.elb: Refreshing state... (ID: sg-a393a7da)
aws_subnet.ext2: Refreshing state... (ID: subnet-1ea41268)
aws_security_group.ec2: Refreshing state... (ID: sg-9a93a7e3)
aws_subnet.int1: Refreshing state... (ID: subnet-bed21694)
aws_nat_gateway.nat1: Refreshing state... (ID: nat-01976423fc8b38d90)
aws_route.default: Refreshing state... (ID: r-rtb-184a467c1080289494)
aws_elb.default: Refreshing state... (ID: tf-lb-zpltk43k7nbfdb2qkxl7prlvzm)
aws_nat_gateway.nat2: Refreshing state... (ID: nat-0d1707e8dec27c564)
aws_subnet.int2: Refreshing state... (ID: subnet-1ca4126a)
aws_launch_configuration.default: Refreshing state... (ID: terraform-ixxb7tbcirax3d7utq4rvyl7f4)
aws_route_table.nat1rt: Refreshing state... (ID: rtb-6d373b09)
aws_route_table.nat2rt: Refreshing state... (ID: rtb-6e373b0a)
aws_route_table_association.nat1rta: Refreshing state... (ID: rtbassoc-8bfb73ec)
aws_route_table_association.nat2rta: Refreshing state... (ID: rtbassoc-8cfb73eb)
aws_route53_record.default: Refreshing state... (ID: Z2EBPSP8GXVCP4_havoc.racker.tech_A)
aws_autoscaling_group.default: Refreshing state... (ID: tf-asg-p7hze3lrzzetzbqozpzi24lnqu)
aws_autoscaling_schedule.default: Refreshing state... (ID: fresh and clean)
aws_autoscaling_policy.step-down: Refreshing state... (ID: step down)
aws_autoscaling_policy.step-up: Refreshing state... (ID: step up)
aws_cloudwatch_metric_alarm.cool: Refreshing state... (ID: cooling-off)
aws_cloudwatch_metric_alarm.hot: Refreshing state... (ID: heating-up)
aws_vpc.default: Modifying...
  tags.Name: "HAVOC-DEV" => "HAVOC-DEV-VPC"
aws_vpc.default: Modifications complete
aws_subnet.ext2: Modifying...
  tags.Name: "EXT2" => "HAVOC-DEV-EXT2"
aws_subnet.ext1: Modifying...
  tags.Name: "EXT1" => "HAVOC-DEV-EXT1"
aws_security_group.elb: Modifying...
  tags.Name: "HAVOC-SG-ELB" => "HAVOC-DEV-ELB-SG"
aws_subnet.ext2: Modifications complete
aws_subnet.int2: Modifying...
  tags.Name: "INT2" => "HAVOC-DEV-INT2"
aws_route_table.nat2rt: Modifying...
  tags.Name: "NAT2-ROUTING" => "HAVOC-DEV-NAT2-RT"
aws_subnet.ext1: Modifications complete
aws_route_table.nat1rt: Modifying...
  tags.Name: "NAT1-ROUTING" => "HAVOC-DEV-NAT1-RT"
aws_subnet.int1: Modifying...
  tags.Name: "INT1" => "HAVOC-DEV-INT1"
aws_subnet.int2: Modifications complete
aws_security_group.elb: Modifications complete
aws_elb.default: Modifying...
  tags.Name: "HAVOC-ELB" => "HAVOC-DEV-ELB"
aws_security_group.ec2: Modifying...
  tags.Name: "HAVOC-SG-EC2" => "HAVOC-DEV-EC2-SG"
aws_route_table.nat2rt: Modifications complete
aws_subnet.int1: Modifications complete
aws_route_table.nat1rt: Modifications complete
aws_security_group.ec2: Modifications complete
aws_elb.default: Modifications complete
aws_autoscaling_group.default: Modifying...
  tag.1637732627.key:                 "" => "Name"
  tag.1637732627.propagate_at_launch: "" => "1"
  tag.1637732627.value:               "" => "HAVOC-DEV-ASG"
  tag.244279944.key:                  "Name" => ""
  tag.244279944.propagate_at_launch:  "1" => "0"
  tag.244279944.value:                "HAVOC-DEV" => ""
aws_autoscaling_group.default: Modifications complete

Apply complete! Resources: 0 added, 11 changed, 0 destroyed.

```

Voila!



`more later...`



[havoc]: https://github.com/dearing/havoc_server
[hasicorp]: https://www.hashicorp.com/
[hcl]: https://github.com/hashicorp/hcl
[terraform]: https://www.terraform.io/
[terraform plugin]: https://packagecontrol.io/packages/Terraform
