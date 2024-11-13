variable "region" {
  type    = string
  default = "us-west-2"
}

data aws_caller_identity current {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  bucket = "whc-app-${var.region}"
  release = "1.0-${data.git_repository.repo.commit_hash}"
  image_tag = "latest"
  gh_repository_name = "ghcr.io/cwells/whc_demo"
}
