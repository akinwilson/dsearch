resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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
    },
    {
        "Effect" : "Allow",
        "Action" : [    
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow"
        "Action": [
            "elasticfilesystem:ClientMount"
            "elasticfilesystem:ClientWrite"
            "elasticfilesystem:ClientRootAccess"    
        ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda_indexer" {
    image_uri = var.indexer_image_uri

    function_name = "lambda_indexer_function"
    role          = aws_iam_role.iam_for_lambda.arn
    handler       = "indexer.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
#   source_code_hash = filebase64sha256("lambda_function_payload.zip")

    runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
    }
  }
}



# A lambda function connected to an EFS file system
resource "aws_lambda_function" "main" {
  # ... other configuration ...

  file_system_config {
    # EFS file system access point ARN
    arn = var.access_point_lambda_arn
    # Local mount path inside the lambda function. Must start with '/mnt/'.
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = [var.subnets]
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  }

  # Explicitly declare dependency on EFS mount target.
  # When creating or updating Lambda functions, mount target must be in 'available' lifecycle state.
  depends_on = [var.dependency_on_mnt]
}
