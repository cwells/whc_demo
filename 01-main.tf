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

data "git_repository" "repo" {
  path = "${path.module}"
}

data "template_file" "Dockerrun" {
  template = "${file("${path.module}/Dockerrun.aws.tpl")}"
  vars = {
    image = "${local.gh_repository_name}:${local.image_tag}"
  }
}

resource "aws_s3_bucket" "whc_app_ebs" {
  bucket = local.bucket
  tags = {
    Name = "whc app ebs"
  }
}

resource "aws_s3_object" "whc_app_deployment" {
  bucket = aws_s3_bucket.whc_app_ebs.id
  key    = "Dockerrun.aws.json"
  content = "${data.template_file.Dockerrun.rendered}"
  force_destroy = true
  etag   = "${filemd5("${path.module}/Dockerrun.aws.tpl")}"
}

resource "aws_s3_bucket_ownership_controls" "whc_app_deployment" {
  bucket = aws_s3_bucket.whc_app_ebs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "whc_app_deployment" {
  depends_on = [aws_s3_bucket_ownership_controls.whc_app_deployment]

  bucket = aws_s3_bucket.whc_app_ebs.id
  acl = "private"
}