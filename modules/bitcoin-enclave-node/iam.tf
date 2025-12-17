resource "aws_iam_role" "enclave_ec2_role" {
  name = "BitcoinEnclaveEC2Role"
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
  name        = "NitroEnclavesPolicy"
  description = "Policy for EC2 to manage Nitro Enclaves and SSM"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
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
    ]
  })
}

resource "aws_iam_role_policy_attachment" "enclave_policy_attachment" {
  role       = aws_iam_role.enclave_ec2_role.name
  policy_arn = aws_iam_policy.enclave_policy.arn
}

resource "aws_iam_instance_profile" "enclave_instance_profile" {
  name = "BitcoinEnclaveInstanceProfile"
  role = aws_iam_role.enclave_ec2_role.name
}
