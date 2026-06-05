
resource "aws_ecr_repository" "app" {
  name                 = "${var.name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name}-app"
  })
}

resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
