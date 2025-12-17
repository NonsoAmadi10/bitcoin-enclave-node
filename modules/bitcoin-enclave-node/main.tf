data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "enclave_host" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.enclave_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.enclave_node_sg.id]
  
  enclave_options {
    enabled = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -ex
              
              # Update and install dependencies
              yum update -y
              yum install -y amazon-linux-extras docker git
              
              # Start Docker service
              systemctl enable docker
              systemctl start docker
              
              # Add ec2-user to the docker group
              usermod -aG docker ec2-user
              
              # Install Nitro Enclaves CLI
              amazon-linux-extras install aws-nitro-enclaves-cli -y
              
              # Add ec2-user to the ne group for Nitro Enclaves device access
              usermod -aG ne ec2-user
              
              # Configure and start the enclave allocator service
              echo "Starting Nitro Enclaves allocator service..."
              systemctl enable nitro-enclaves-allocator.service
              systemctl start nitro-enclaves-allocator.service
              EOF

  tags = {
    Name = "Bitcoin-Enclave-Host"
  }
}
