
output "repository_url" {
  description = "URL of the ECR repository."
  value       = aws_ecr_repository.app.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.app.name
}

output "nginx_image" {
  description = "Private ECR pull-through cache image URL for nginx."
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_pull_through_cache_rule.ecr_public.ecr_repository_prefix}/nginx/nginx:stable"
}
