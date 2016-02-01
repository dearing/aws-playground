# resource "aws_codedeploy_app" "havoc" {
#   name = "havoc"
# }

# resource "aws_iam_role_policy" "code" {
#     name = "code_policy"
#     role = "${aws_iam_role.code.id}"
#     policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "autoscaling:CompleteLifecycleAction",
#                 "autoscaling:DeleteLifecycleHook",
#                 "autoscaling:DescribeAutoScalingGroups",
#                 "autoscaling:DescribeLifecycleHooks",
#                 "autoscaling:PutLifecycleHook",
#                 "autoscaling:RecordLifecycleActionHeartbeat",
#                 "ec2:DescribeInstances",
#                 "ec2:DescribeInstanceStatus",
#                 "tag:GetTags",
#             "tag:GetResources"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF
# }

# resource "aws_iam_role" "code" {
#     name = "code"
#     assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": [
#           "codedeploy.amazonaws.com"
#         ]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_codedeploy_deployment_group" "code" {
#     app_name = "${aws_codedeploy_app.havoc.name}"
#     deployment_group_name = "code"
#     service_role_arn = "${aws_iam_role.code.arn}"
#     autoscaling_groups = ["${aws_autoscaling_group.default.id}"]
# }