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

data "aws_subnet" "default" {
  vpc_id            = var.vpc_id == null ? data.aws_vpc.default.id : var.vpc_id
  availability_zone = data.aws_ami.amazon_linux_2.architecture == "x86_64" ? "us-east-1a" : "us-east-1a" # Example, can be improved
}

resource "aws_instance" "enclave_host" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.enclave_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.enclave_node_sg.id]
  subnet_id                   = var.subnet_id == null ? data.aws_subnet.default.id : var.subnet_id
  
  enclave_options {
    enabled = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -ex
              
              # Update and install dependencies
              yum update -y
              yum install -y amazon-linux-extras docker git jq -y
              
              # Install Go
              echo "Installing Go..."
              amazon-linux-extras install golang1.18 -y
              
              # Start Docker service
              systemctl enable docker
              systemctl start docker
              
              # Add ec2-user to the docker group
              usermod -aG docker ec2-user
              
              # Install Nitro Enclaves CLI
              amazon-linux-extras install aws-nitro-enclaves-cli -y
              
              # Add ec2-user to the ne group for Nitro Enclaves device access
              usermod -aG ne ec2-user
              
              # Clone the application repository
              sudo -u ec2-user git clone "${var.git_repository_url}" /home/ec2-user/app
              
              # Configure and start the enclave allocator service
              echo "Starting Nitro Enclaves allocator service..."
              systemctl enable nitro-enclaves-allocator.service
              systemctl start nitro-enclaves-allocator.service
              
              # --- Enclave Setup Script ---
              cat > /home/ec2-user/setup_enclave.sh << 'SETUP_SCRIPT_EOF'
              #!/bin/bash
              set -ex
              
              ENCLAVE_APP_DIR="/home/ec2-user/app/enclave_app"
              EIF_PATH="/home/ec2-user/app/enclave.eif"
              PARENT_APP_BINARY="/home/ec2-user/app/enclave-broker"
              
              ENCLAVE_NAME="${local.enclave_name}"
              ENCLAVE_CPU_COUNT=${var.enclave_cpu_count}
              ENCLAVE_MEMORY_MIB=${var.enclave_memory_mib}
              EXPECTED_MEASUREMENT="${var.expected_measurement}"
              KMS_KEY_ARN="${var.kms_key_arn}"
              AWS_REGION="${var.aws_region}"

              # Navigate to the application directory
              cd "$ENCLAVE_APP_DIR"
              
              # Tidy Go modules
              echo "Tidying Go modules..."
              sudo -u ec2-user /usr/bin/go mod tidy
              
              # Build the parent/broker Go application
              echo "Building parent Go application..."
              sudo -u ec2-user /usr/bin/go build -o "$PARENT_APP_BINARY" ./src/main.go
              
              # Build the Docker image for the enclave
              echo "Building Docker image for enclave application..."
              docker build -t enclave-app .
              
              # Convert Docker image to EIF
              echo "Converting Docker image to EIF..."
              nitro-cli build-enclave --docker-uri enclave-app:latest --output-file "$EIF_PATH"
              
              # Verify EIF measurement against expected PCR0
              ACTUAL_MEASUREMENT=$(nitro-cli describe-eif --eif-path "$EIF_PATH" | jq -r .Measurements.PCR0)
              echo "Actual EIF PCR0 Measurement: $ACTUAL_MEASUREMENT"
              echo "Expected PCR0 Measurement: $EXPECTED_MEASUREMENT"

              if [ -n "$EXPECTED_MEASUREMENT" ] && [ "$ACTUAL_MEASUREMENT" != "$EXPECTED_MEASUREMENT" ]; then
                echo "ERROR: EIF PCR0 measurement mismatch! Expected $EXPECTED_MEASUREMENT, got $ACTUAL_MEASUREMENT"
                exit 1
              fi
              echo "EIF PCR0 measurement verified successfully (or was not provided)."

              # Create a systemd service for the parent application (broker)
              cat > /etc/systemd/system/enclave-broker.service << EOF_SERVICE
[Unit]
Description=Nitro Enclave Broker Application (Go)
After=network-online.target nitro-enclaves-allocator.service
Wants=network-online.target nitro-enclaves-allocator.service

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/app
ExecStart=$PARENT_APP_BINARY \\
    --eif-path="$EIF_PATH" \\
    --enclave-name="$ENCLAVE_NAME" \\
    --cpu-count="$ENCLAVE_CPU_COUNT" \\
    --memory-mib="$ENCLAVE_MEMORY_MIB" \\
    --expected-measurement="$EXPECTED_MEASUREMENT" \\
    --kms-key-arn="$KMS_KEY_ARN" \\
    --aws-region="$AWS_REGION"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF_SERVICE

              echo "Enabling and starting enclave-broker service..."
              systemctl daemon-reload
              systemctl enable enclave-broker.service
              systemctl start enclave-broker.service
              
              echo "Enclave setup script finished."
              SETUP_SCRIPT_EOF
              
              chmod +x /home/ec2-user/setup_enclave.sh
              # Execute as root, since the script now writes to /etc/systemd/system
              /home/ec2-user/setup_enclave.sh
              EOF

  tags = {
    Name = "${var.name_prefix}-host"
  }
}
