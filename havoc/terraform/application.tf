# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name = "havoc-elb-sg"
  description = "HAVOC ELB SG"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${lookup(var.vpc_cidrs, "VPC")}"]
  }

  tags {
    Name = "HAVOC-SG-ELB"
  }
}

resource "aws_security_group" "ec2" {
  name = "havoc-ec2-sg"
  description = "HAVOC EC2 SG"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${lookup(var.vpc_cidrs, "VPC")}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${aws_security_group.elb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "HAVOC-SG-EC2"
  }
}


resource "aws_elb" "default" {
  subnets         = ["${aws_subnet.ext1.id}", "${aws_subnet.ext2.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  cross_zone_load_balancing = true
  idle_timeout        = 60
  connection_draining = true
  connection_draining_timeout = 60

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"  # *.racker.tech
    ssl_certificate_id = "arn:aws:acm:us-east-1:595430538023:certificate/5d611a4a-6348-4134-9ccd-4b92e25469ac"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout = 10
    target = "HTTP:8080/"
    interval = 30
  }

  tags {
    Name = "HAVOC-ELB"
  }
}

resource "aws_key_pair" "default" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


resource "aws_launch_configuration" "default" {
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.small"
  security_groups = ["${aws_security_group.ec2.id}"]
  # user_data = "${file("userdata.sh")}"
  key_name = "${var.key_name}"
  enable_monitoring = true
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "default" {
  vpc_zone_identifier = ["${aws_subnet.int1.id}","${aws_subnet.int2.id}"]
  max_size = 6
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  load_balancers = ["${aws_elb.default.name}"]
  launch_configuration = "${aws_launch_configuration.default.name}"

  tag {
    key = "Name"
    value = "HAVOC-DEV"
    propagate_at_launch = true
  }
}

resource "aws_route53_record" "default" {
  zone_id = "Z2EBPSP8GXVCP4"
  name = "havoc.racker.tech"
  type = "A"

  alias {
    name = "${aws_elb.default.dns_name}"
    zone_id = "${aws_elb.default.zone_id}"
    evaluate_target_health = true
  }
}