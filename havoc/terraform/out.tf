output "address" {
  value = "${aws_elb.havoc_web_elb.dns_name}"
}
