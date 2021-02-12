# Specify the provider and access details
provider "aws" {
  region = "eu-west-1"
  access_key = "test"
  secret_key = "test"
  s3_force_path_style = true
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    vpc     = "http://localhost:4566"
  }
}

# Create a VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "example_gateway" {
  vpc_id = aws_vpc.example_vpc.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "example_subnet" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.10.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = var.aws_zone
}

resource "aws_route" "example_route" {
  route_table_id = aws_vpc.example_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.example_gateway.id
}

# Security group for our application.
resource "aws_security_group" "example_security_group" {
  name        = "example_security_group"
  description = "Security group for example application"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9990
    to_port     = 9990
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2375
    to_port     = 2375
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "filename" {
  default = "cloud-config.cfg"
}

data "template_file" "template" {
  template = <<EOF
#cloud-config
users:
  - name: $${admin_user}
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - $${admin_key_public}
EOF
  vars = {
    admin_user = var.admin_user
    admin_key_public = var.admin_key_public
  }
}

resource "aws_instance" "example_vm" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = var.admin_user
  }

  instance_type = "t2.micro"

  tags = {
    Name = "example-vm"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = lookup(var.aws_amis, var.aws_region)

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.example_security_group.id]

  # Connect to subnet
  subnet_id = aws_subnet.example_subnet.id

  user_data =   data.template_file.template.rendered
}

resource "aws_eip" "eip" {
  instance = aws_instance.example_vm.id
  vpc      = true
}
