terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "EG-workloads"
  region  = "us-west-2"
}

resource "aws_s3_bucket" "demo" {
	bucket = "eg-prowler-demo-intentionally-vulnerable"
}

resource "aws_iam_user" "demo" {
	name = "demo-no-mfa-user"
}

resource "aws_iam_access_key" "demo" {
	user = aws_iam_user.demo.name
}

resource "aws_security_group" "demo" {
    name_prefix = "prowler-demo-no-ssh"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "demo" {
  ami                       = "ami-08b7b9fdd7a1edf3d"
  instance_type             = "t3.micro"
  vpc_security_group_ids = [aws_security_group.demo.id]
  associate_public_ip_address = true
  # omtting metadata options and leaving IMDSv1 allowed
  # omitting root block device encryption
}