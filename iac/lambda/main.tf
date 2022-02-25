
resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-lambda-role"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid = "AllowLambdaExecution"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
  })
}

resource "aws_iam_policy" "efs_attachment_policy" {
  name        = "${var.name}-lambda-efs"
  description = "Policy that allows access EFS, mounting reading and writing"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:DescribeNetworkInterfacePermissions",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeRegions",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-execution-role-policy-attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.efs_attachment_policy.arn
}


# A lambda function connected to an EFS file system
resource "aws_lambda_function" "main" {

  image_uri     = "${var.indexer_container_repo}/${var.name}-indexer-${var.environment}:latest"
  function_name = "lambda_indexer_function"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 120
  memory_size   = 1000
  package_type  = "Image"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      HTTP_ADDR   = "0.0.0.0:7700"
      MASTER_KEY  = var.master_key
    }
  }
  file_system_config {
    arn = var.access_point
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [var.sg]
  }

  depends_on = [var.dependency_on_mnt, var.dependency_on_ecr]
}


resource "aws_cloudwatch_event_rule" "main" {
    name = "every-five-minutes"
    description = "Fires every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "main" {
    rule = "${aws_cloudwatch_event_rule.main.name}"
    target_id = "lambda_indexer_function"
    arn = "${aws_lambda_function.main.arn}"
}

resource "aws_lambda_permission" "main" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.main.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.main.arn}"
}
