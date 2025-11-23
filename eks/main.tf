####################################################################
#
#
#
####################################################################

variable "aws_region" {
  type    = string
  default = "us-east-1"
}



output "NodeInstanceRole" {
  value = aws_iam_role.node_instance_role.arn
}

output "NodeSecurityGroup" {
  value = aws_security_group.node_security_group.id
}

output "NodeAutoScalingGroup" {
  value = aws_cloudformation_stack.autoscaling_group.outputs["NodeAutoScalingGroup"]
}

