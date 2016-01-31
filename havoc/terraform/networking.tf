/*
  ======================================================
    'VIRTUAL PRIVATE CLOUD'
  ======================================================
*/

resource "aws_vpc" "default" {
  cidr_block = "${lookup(var.vpc_cidrs, "VPC")}"
  tags {
    Name = "HAVOC-DEV"
  }
}

/*
  ======================================================
    'AVAILABILITY ZONE // PRIMARY'
  ======================================================
*/

# SUBNET EXTERNAL 01
resource "aws_subnet" "ext1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "EXT1")}"
  availability_zone       = "${lookup(var.zones, "primary")}"
  map_public_ip_on_launch = true
  tags {
    Name = "EXT1"
  }
}
# SUBNET INTERNAL 01
resource "aws_subnet" "int1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "INT1")}"
  availability_zone       = "${aws_subnet.ext1.availability_zone}"
  map_public_ip_on_launch = false
  tags {
    Name = "INT1"
  }
}

/*
  ======================================================
    'AVAILABILITY ZONE // SECONDARY'
  ======================================================
*/


# SUBNET EXTERNAL 02
resource "aws_subnet" "ext2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "EXT2")}"
  availability_zone       = "${lookup(var.zones, "secondary")}"  
  map_public_ip_on_launch = true
  tags {
    Name = "EXT2"
  }
}
# SUBNET INTERNAL 02
resource "aws_subnet" "int2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "INT2")}"
  availability_zone       = "${aws_subnet.ext2.availability_zone}"
  map_public_ip_on_launch = false
  tags {
    Name = "INT2"
  }
}

/*
  ======================================================
    'INTERNET Gateway and Route'
  ======================================================
*/


# INTERNET GATEWAY for VPC
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "HAVOC-DEV-IG"
  }
}

# DEFAULT ROUTE for INTERNET GATEWAY EXT 01-02
resource "aws_route" "default" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

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



# EIP and NAT GATEWAY for SUBNET EXT/INT 02
resource "aws_eip" "nat2" {
  vpc = true
}
resource "aws_nat_gateway" "nat2" {
  allocation_id = "${aws_eip.nat2.id}"
  subnet_id = "${aws_subnet.ext2.id}"
  depends_on = ["aws_internet_gateway.default"]
}
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
# ASSOCIATE our ROUTE TABLE to the INTERNAL SUBNET 02
resource "aws_route_table_association" "nat2rta" {
  subnet_id = "${aws_subnet.int2.id}"
  route_table_id = "${aws_route_table.nat2rt.id}"
}
