resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.name}/app"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name}-app-logs"
  })
}

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.name}-eks-node-cpu-high"
  alarm_description   = "Alarm when average EKS node CPU utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.cpu_alarm_threshold
  period              = 300
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/EKS"
  metric_name = "node_cpu_utilization"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(var.tags, {
    Name = "${var.name}-eks-node-cpu-high"
  })
}
