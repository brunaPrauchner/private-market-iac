# Private Market IaC

Terraform project that deploys a private AWS EKS environment and a simple containerized application.

## Architecture

- AWS VPC with private subnets across two Availability Zones
- No internet gateway
- No NAT gateway
- VPC endpoints for private AWS service access
- Amazon ECR for the application image
- Amazon EKS with a managed node group
- Basic observability with CloudWatch

## Design Notes

The cluster is intentionally private. Worker nodes run in private subnets and do not receive public IP addresses. Since there is no internet gateway or NAT gateway, AWS service access is provided through VPC endpoints.

For the demo, the managed node group uses one small node to reduce cost. In a production environment, I would use at least two nodes across multiple Availability Zones and tune autoscaling based on workload needs.

## Prerequisites

- AWS account
- AWS CLI
- Terraform
- kubectl
- IAM Identity Center profile configured locally

## AWS Authentication
This project uses AWS IAM Identity Center (AWS SSO) for local authentication.

Benefits of IAM Identity Center over long-lived IAM access keys:

- Uses short-lived credentials instead of permanent access keys
- Reduces the risk of leaked credentials
- Supports centralized user access management
- Makes it easier to revoke or rotate access
- Better reflects how production AWS access is commonly managed

Login using IAM Identity Center:

```powershell
aws sso login --profile terraform-dev