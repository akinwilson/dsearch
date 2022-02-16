
resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-lambda-role"
   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "efs_attachment_policy" {
  name        = "${var.name}-lambda-efs"
  description = "Policy that allows access EFS, mounting reading and writing"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "elasticfilesystem:ClientMount",
              "elasticfilesystem:ClientWrite",
              "elasticfilesystem:ClientRootAccess"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-execution-role-policy-attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.efs_attachment_policy.arn
}


# A lambda function connected to an EFS file system
resource "aws_lambda_function" "main" {
    # name        = "${var.name}-indexer-${var.environment}"
    image_uri       = "${var.indexer_container_repo}/${var.name}-indexer-${var.environment}:latest" # 437996125465.dkr.ecr.eu-west-2.amazonaws.com/e2e-search-retriever-prod:latest
    # image_uri = var.indexer_image_uri # 437996125465.dkr.ecr.eu-west-2.amazonaws.com/e2e-search-indexer-prod:latest
    function_name = "lambda_indexer_function"
    role = aws_iam_role.lambda_role.arn
    handler = "indexer.handler"
    runtime = "python3.8"
    timeout = 120
    
    environment {
        variables = {
            ENVIRONMENT = var.environment 
            HTTP_ADDR="0.0.0.0:7700"
            MASTER_KEY = var.master_key 
        }
  }
  file_system_config {
    # EFS file system access point ARN
    arn = var.access_point_lambda_arn
    # Local mount path inside the lambda function. Must start with '/mnt/'.
    local_mount_path = "/mnt/efs"
  }
  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = var.subnets
    security_group_ids = [var.sg_lambda_efs]
  }

  # Explicitly declare dependency on EFS mount target.
  # When creating or updating Lambda functions, mount target must be in 'available' lifecycle state.
  depends_on = [var.dependency_on_mnt]
}
