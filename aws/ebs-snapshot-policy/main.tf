# IAM role 
resource "aws_iam_role" "dlm_lifecycle_role" {
  name = var.role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM role policy
resource "aws_iam_role_policy" "dlm_lifecycle" {
  name = var.policy_name
  role = aws_iam_role.dlm_lifecycle_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:DescribeVolumes",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

# Lifecycle policy for snapshot
resource "aws_dlm_lifecycle_policy" "instance_snapshot" {
  description        = "Snapshot lifecycle policy for target instance"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"
  policy_details {
    resource_types = ["VOLUME"]
    schedule {
      name = var.schedule_name
      create_rule {
        interval      = var.interval
        interval_unit = var.interval_unit
        times         = var.times
      }
      retain_rule {
        count         = var.number_of_snapshots_retained
      }
      tags_to_add     = var.snapshot_tag
    }
    target_tags = var.volume_target_tag
  }
  tags = var.tag
}