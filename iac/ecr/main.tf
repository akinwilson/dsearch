resource "aws_ecr_repository" "indexer_main" {
  name                 = "${var.name}-indexer-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  provisioner "local-exec" {
    command = "../app/push-to-ecr.sh ${var.name} ${var.environment} indexer dockerfile.lambdaIndexer"
  }
}

resource "aws_ecr_repository" "retriever_main" {
  name                 = "${var.name}-retriever-${var.environment}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  provisioner "local-exec" {
    command = "../app/push-to-ecr.sh ${var.name} ${var.environment} retriever dockerfile.searchEngine"
  }
}

resource "aws_ecr_lifecycle_policy" "retriever_main" {
  repository = aws_ecr_repository.retriever_main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 1 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}


resource "aws_ecr_lifecycle_policy" "indexer_main" {
  repository = aws_ecr_repository.indexer_main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 1 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}


output "aws_ecr_retriever_repo_url" {
  value = aws_ecr_repository.retriever_main.repository_url
}

output "aws_ecr_indexer_repo_url" {
  value = aws_ecr_repository.indexer_main.repository_url
}

output "dependency_on_ecr" {
  value = aws_ecr_repository.indexer_main

}
