resource "aws_iam_role" "enclave_ec2_role" {
  name = "${var.name_prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "enclave_policy" {
  name        = "${var.name_prefix}-enclave-policy"
  description = "Policy for EC2 to manage Nitro Enclaves and SSM"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = concat([
      {
        Effect   = "Allow",
        Action   = "ec2:DescribeInstances",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ne:*"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action = [
            "ssm:UpdateInstanceInformation",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      }
    ],
    var.kms_key_arn != null ? [
      {
        Effect   = "Allow",
        Action   = [
          "kms:Decrypt",
          "kms:GenerateDataKey" # Potentially needed for re-encrypting or generating new keys
        ],
        Resource = var.kms_key_arn
      }
    ] : [])
  })
}

resource "aws_iam_role_policy_attachment" "enclave_policy_attachment" {
  role       = aws_iam_role.enclave_ec2_role.name
  policy_arn = aws_iam_policy.enclave_policy.arn
}

resource "aws_iam_instance_profile" "enclave_instance_profile" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.enclave_ec2_role.name
}
