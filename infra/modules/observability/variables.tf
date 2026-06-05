variable "name" {
  description = "Name prefix for observability resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for CloudWatch dimensions."
  type        = string
}

variable "log_retention_days" {
  description = "Retention period for the application CloudWatch log group."
  type        = number
  default     = 7
}

variable "cpu_alarm_threshold" {
  description = "Average node CPU utilization percentage that triggers the alarm."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags applied to observability resources."
  type        = map(string)
}
