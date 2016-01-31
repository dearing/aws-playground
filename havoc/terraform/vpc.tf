# ==[ VPC ]==============================

# Create a VPC to launch our instances into
resource "aws_vpc" "havoc" {
  cidr_block = "${lookup(var.vpc_cidrs, "vpc")}"
  tags {
    Name = "HAVOC-VPC-DEV"
  }
}

# Create a subnet to launch our instances into
resource "aws_subnet" "ext1" {
  vpc_id                  = "${aws_vpc.havoc.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "ext-1")}"
  map_public_ip_on_launch = true
  tags {
    Name = "EXT1"
  }
}
# Create a subnet to launch our instances into
resource "aws_subnet" "int1" {
  vpc_id                  = "${aws_vpc.havoc.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "int-1")}"
  map_public_ip_on_launch = true
  tags {
    Name = "INT1"
  }
}

# Create a subnet to launch our instances into
resource "aws_subnet" "ext2" {
  vpc_id                  = "${aws_vpc.havoc.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "ext-2")}"
  map_public_ip_on_launch = true
  tags {
    Name = "EXT2"
  }
}

# Create a subnet to launch our instances into
resource "aws_subnet" "int2" {
  vpc_id                  = "${aws_vpc.havoc.id}"
  cidr_block              = "${lookup(var.vpc_cidrs, "int-2")}"
  map_public_ip_on_launch = true
  tags {
    Name = "INT2"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "havoc-internet-gateway" {
  vpc_id = "${aws_vpc.havoc.id}"
  tags {
    Name = "HAVOC-IG-DEV"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.havoc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.havoc-internet-gateway.id}"
}


# ==[ ELB ]==============================

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "havoc_elb_sg" {
  name        = "havoc_elb_sg"
  description = "HAVOC ELB SG"
  vpc_id      = "${aws_vpc.havoc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${lookup(var.vpc_cidrs, "ext-1")}"]
  }

  tags {
    Name = "HAVOC-ELB-SG"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "havoc_ec2_sg" {
  name        = "havoc_ec2_sg"
  description = "havoc web servers"
  vpc_id      = "${aws_vpc.havoc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${lookup(var.vpc_cidrs, "vpc")}"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${havoc_elb_sg}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "HAVOC-EC2-SG"
  }
}


resource "aws_elb" "havoc_web_elb" {
  # name = ""

  subnets         = ["${aws_subnet.ext1.id}"]
  security_groups = ["${aws_security_group.havoc_elb_sg.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:595430538023:certificate/5d611a4a-6348-4134-9ccd-4b92e25469ac"
  }
  tags {
    Name = "HAVOC-ELB"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


resource "aws_launch_configuration" "havoc_ec2_lg" {
  # name = "terraform-example-lc"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.medium"
  # Security group
  security_groups = ["${aws_security_group.havoc_ec2_sg.id}"]
  # user_data = "${file("userdata.sh")}"
  key_name = "${var.key_name}"
}


resource "aws_autoscaling_group" "havoc_ec2_sg" {
  # availability_zones = ["us-east-1a"]
  # name = "foobar3-terraform-test"
  max_size = 4
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 2
  vpc_zone_identifier = ["${aws_subnet.int1.id}", "${aws_subnet.int1.id}"]
  load_balancers = ["${aws_elb.havoc_web_elb.name}"]
  launch_configuration = "${aws_launch_configuration.havoc_ec2_lg.name}"
  tag {
    key = "Name"
    value = "HAVOC-DEV"
    propagate_at_launch = true
  }
}

