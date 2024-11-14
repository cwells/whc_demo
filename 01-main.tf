terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    git = {
      source  = "paultyng/git"
      version = "~> 0.1.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Fetch the repository details from a local Git repository.
data "git_repository" "repo" {
  path = "${path.module}"
}

# Use the template file "Dockerrun.aws.tpl" and insert values for the Docker image.
data "template_file" "Dockerrun" {
  template = "${file("${path.module}/Dockerrun.aws.tpl")}"
  vars = {
    image = "${local.gh_repository_name}:${local.image_tag}"
  }
}

# Create an S3 bucket for storing application deployment files.
resource "aws_s3_bucket" "whc_app_ebs" {
  bucket = local.bucket
  tags = {
    Name = "whc app ebs"
  }
}

# Upload the Dockerrun file to the S3 bucket for use by Elastic Beanstalk.
resource "aws_s3_object" "whc_app_deployment" {
  bucket = aws_s3_bucket.whc_app_ebs.id
  key    = "Dockerrun.aws.json"
  content = "${data.template_file.Dockerrun.rendered}"
  force_destroy = true
  # Use file hash to trigger updates when the template changes
  etag   = "${filemd5("${path.module}/Dockerrun.aws.tpl")}"
}

# Set the ownership controls for the S3 bucket, giving ownership preference to the bucket owner.
resource "aws_s3_bucket_ownership_controls" "whc_app_deployment" {
  bucket = aws_s3_bucket.whc_app_ebs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set the S3 bucket's ACL to "private".
resource "aws_s3_bucket_acl" "whc_app_deployment" {
  depends_on = [aws_s3_bucket_ownership_controls.whc_app_deployment]

  bucket = aws_s3_bucket.whc_app_ebs.id
  acl = "private"
}