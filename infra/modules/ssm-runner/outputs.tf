output "instance_id" {
  description = "Instance ID of the private SSM runner."
  value       = aws_instance.this.id
}

output "role_arn" {
  description = "IAM role ARN used by the private SSM runner."
  value       = aws_iam_role.this.arn
}

output "security_group_id" {
  description = "Security group ID of the private SSM runner."
  value       = aws_security_group.this.id
}
