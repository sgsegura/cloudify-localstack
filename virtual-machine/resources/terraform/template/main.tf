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
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

resource "aws_instance" "example_vm" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "admin"
  }

  instance_type = "t2.micro"

  tags = {
    Name = "example-vm"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-0eee6eb870dc1cefa"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-test-s3-terraform-bucket"
}
