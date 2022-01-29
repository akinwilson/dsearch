data "aws_iam_policy_document" "iam_policy_document" {
    statement {
      sid = "AllowSpecificS3FullAccess"
      actions = ["s3:*"]
      effect = "Allow"
      resources = [
          "arn:aws:s3:::*/*",
          "arn:aws:s3:::*",
          "arn:aws:s3:::search-infra-euw2",
          "arn:aws:s3:::search-infra-euw2",
      ]
    }
    statement {
        sid = "AllowSecurityGroups"
        actions = [
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSecurityGroupsRules",
            "ec2:DescribeTags",
            "ec2:CreateTags",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:ModifySecurityGroupEgress",
            "ec2:ModifySecurityGroupRuleDescriptionIngress",
            "ec2:ModifySecurityGroupRuleDescriptionEgress",
            "ec2:ModifySecurityGroupRules",
            "ec2:CreateSecurityGroup"
        ]
        effect = "Allow"
        resources =["*"]
    }
    statement {
        sid = "AllowEC2"
        action = [
            "ec2:*"
            ]
        effect = "Allow"
        resources =["*"]
    }
    statement {
        sid = "AllowIAM"
        actions= [
            "iam:*"
        ]
        effect = "Allow"
        resources = ["*"]
    }
    statement {
        sid = "AllowSecretsManager"
        actions = [
        "secretsmanager:*"
        ]
        effect = "Allow"
        resources = ["*"]
    }
    statement {
        sid = "AllowSSM"
        actions = [
        "ssm:PutParameter",
        "ssm:DeleteParameter",
        "ssm:GetParameterHistory",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:GetParameter",
        "ssm:DeleteParameters",
        "ssm:DescribeParameters",
        "ssm:AddTagsToResource",
        "ssm:ListTagsForResource"
        ]
        effect    = "Allow"
        resources = ["*"]
        }
}

resource "aws_iam_policy" "iam_policy" {
    name = "terraform-iam-policy"
    path = "/"
    policy = data.aws_iam_policy_document.iam_policy_document.json  
}

resource "aws_iam_user" "terraform_user" {
    name = "terraform_agent_user"
}
resource "aws_iam_user_policy_attachment" "tf_attach" {
    user = aws_iam_user.terraform_agent_user.name
    policy_arn = aws_iam_policy.iam_policy.arn
}
