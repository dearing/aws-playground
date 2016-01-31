# ==[ VPC ]==============================

resource "aws_vpc" "default" {
  cidr_block = "${lookup(var.vpc_cidrs, "vpc")}"
  tags {
    Name = "HAVOC-DEV"
  }
}

resource "aws_subnet" "ext1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "ext-1")}"
  availability_zone       = "${lookup(var.zones, "primary")}"
  map_public_ip_on_launch = true
  tags {
    Name = "EXT1"
  }
}
resource "aws_subnet" "int1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "int-1")}"
  availability_zone       = "${aws_subnet.ext1.availability_zone}"
  map_public_ip_on_launch = false
  tags {
    Name = "INT1"
  }
}
resource "aws_subnet" "ext2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "ext-2")}"
  availability_zone       = "${lookup(var.zones, "secondary")}"  
  map_public_ip_on_launch = true
  tags {
    Name = "EXT2"
  }
}
resource "aws_subnet" "int2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "int-2")}"
  availability_zone       = "${aws_subnet.ext2.availability_zone}"
  map_public_ip_on_launch = false
  tags {
    Name = "INT2"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "HAVOC-DEV-IG"
  }
}

resource "aws_route" "default" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}


resource "aws_eip" "nat1" {
    vpc = true
}

resource "aws_eip" "nat2" {
    vpc = true
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = "${aws_eip.nat1.id}"
  subnet_id = "${aws_subnet.ext1.id}"
  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = "${aws_eip.nat2.id}"
  subnet_id = "${aws_subnet.ext2.id}"
  depends_on = ["aws_internet_gateway.default"]
}

