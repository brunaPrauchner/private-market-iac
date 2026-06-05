output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "vpc_endpoint_ids" {
  description = "IDs of VPC endpoints required for private EKS node bootstrap and AWS service access."
  value = [
    aws_vpc_endpoint.ecr_api.id,
    aws_vpc_endpoint.ecr_dkr.id,
    aws_vpc_endpoint.s3.id,
    aws_vpc_endpoint.sts.id,
    aws_vpc_endpoint.ec2.id,
    aws_vpc_endpoint.eks.id,
    aws_vpc_endpoint.ssm.id,
    aws_vpc_endpoint.ssm_messages.id,
    aws_vpc_endpoint.ec2_messages.id,
    aws_vpc_endpoint.logs.id,
    aws_vpc_endpoint.eks_auth.id,
  ]
}
