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

# ==[ ELB ]==============================

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name = "havoc-elb-sg"
  description = "HAVOC ELB SG"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${lookup(var.vpc_cidrs, "vpc")}"]
  }

  tags {
    Name = "HAVOC-SG-ELB"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "ec2" {
  name = "havoc-ec2-sg"
  description = "HAVOC EC2 SG"
  vpc_id      = "${aws_vpc.default.id}"

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
    cidr_blocks = ["${aws_security_group.elb.id}"]
  }

  # outbound internet access
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

resource "aws_autoscaling_policy" "step-up" {
  adjustment_type        = "PercentChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.default.name}"
  cooldown               = 60
  min_adjustment_step    = 1
  name                   = "step up"
  scaling_adjustment     = 33
}

resource "aws_autoscaling_policy" "step-down" {
  adjustment_type        = "PercentChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.default.name}"
  cooldown               = 60
  min_adjustment_step    = 1
  name                   = "step down"
  scaling_adjustment     = 33
}


resource "aws_cloudwatch_metric_alarm" "hot" {
    alarm_name = "heating-up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "75"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.default.name}"
    }
    alarm_description = "when the average cpu usage rises, scale up"
    alarm_actions = ["${aws_autoscaling_policy.step-up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cool" {
    alarm_name = "cooling-off"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "25"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.default.name}"
    }
    alarm_description = "when the average cpu usage drops, scale down"
    alarm_actions = ["${aws_autoscaling_policy.step-down.arn}"]
}

resource "aws_autoscaling_schedule" "default" {
    scheduled_action_name = "fresh and clean"
    min_size = 2
    max_size = 6
    desired_capacity = 2
    recurrence = "0 * * * *" # hourly
    autoscaling_group_name = "${aws_autoscaling_group.default.name}"
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
  # availability_zones = ["${aws_subnet.int1.availability_zone}","${aws_subnet.int2.availability_zone}"]
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
  # zone_id = "${aws_route53_zone.default.zone_id}"
  zone_id = "Z2EBPSP8GXVCP4"
  name = "havoc.racker.tech"
  type = "A"

  alias {
    name = "${aws_elb.default.dns_name}"
    zone_id = "${aws_elb.default.zone_id}"
    evaluate_target_health = true
  }
}