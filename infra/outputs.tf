output "app_namespace" {
  description = "Namespace where the demo app is deployed."
  value       = var.deploy_app ? module.app[0].namespace : null
}

output "app_service_name" {
  description = "Private ClusterIP service name for the demo app."
  value       = var.deploy_app ? module.app[0].service_name : null
}

output "app_image" {
  description = "Container image used by the demo app."
  value       = var.deploy_app ? module.app[0].image : null
}

output "ssm_runner_instance_id" {
  description = "Instance ID of the private SSM runner."
  value       = module.ssm_runner.instance_id
}

output "eks_cluster_endpoint" {
  description = "Private EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "observability_log_group" {
  description = "CloudWatch log group used for application logs."
  value       = module.observability.app_log_group_name
}

output "observability_cpu_alarm" {
  description = "CloudWatch alarm for high EKS node CPU."
  value       = module.observability.node_cpu_alarm_name
}
