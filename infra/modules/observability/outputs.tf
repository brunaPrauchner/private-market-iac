output "app_log_group_name" {
  description = "Name of the application CloudWatch log group."
  value       = aws_cloudwatch_log_group.app.name
}

output "node_cpu_alarm_name" {
  description = "Name of the EKS node CPU CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.node_cpu_high.alarm_name
}
