variable "repositories" { type = list(string) }

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repositories)
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # lab: lets terraform destroy remove repos that still hold images
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 15 images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 15 }
      action       = { type = "expire" }
    }]
  })
}

output "repository_urls" { value = { for k, v in aws_ecr_repository.this : k => v.repository_url } }
