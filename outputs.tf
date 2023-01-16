output "asg_name" {
  value = aws_autoscaling_group.this.name
}

output "aws_iam_role_name" {
  value = aws_iam_role.agent.name
}