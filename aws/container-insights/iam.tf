data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:aws-container-insights"]
    }

    principals {
      identifiers = [var.oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "container_insight_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "ContainerInsightRole"
}

resource "aws_iam_policy" "container_insight_policy" {
  name        = "ContainerInsightPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeInstances",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKS_CNI_Policy" {
  policy_arn = aws_iam_policy.container_insight_policy.arn
  role       = aws_iam_role.container_insight_role.name
}