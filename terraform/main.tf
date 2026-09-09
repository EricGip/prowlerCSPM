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

variable "my_ip" {
  type        = string
  description = "public IP in CIDR form, used in security group"
}

resource "aws_guardduty_detector" "demo" {
  enable = true
}

resource "aws_s3_bucket" "demo" {
	bucket = "eg-prowler-demo-intentionally-vulnerable"
}

resource "aws_s3_account_public_access_block" "account" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_user" "demo" {
	name = "demo-no-mfa-user"
}

resource "aws_iam_access_key" "demo" {
	user = aws_iam_user.demo.name
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
}

resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

resource "aws_security_group" "demo" {
    name_prefix = "prowler-demo-no-ssh"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "demo" {
  ami                         = "ami-08b7b9fdd7a1edf3d"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.demo.id]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }
}

resource "aws_ec2_instance_metadata_defaults" "account" {
  http_tokens = "required"
}