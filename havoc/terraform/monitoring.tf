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
  scaling_adjustment     = -33
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
