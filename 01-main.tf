provider aws {
    region = var.region
}
  
locals {
    prefix = "whc"
    account_id = data.aws_caller_identity.current.account_id
    ecr_repository_name = "${local.prefix}-lambda-container"
    ecr_image_tag = "latest"
}
 
data aws_caller_identity current {}

data aws_iam_policy_document cloudwatch {
    statement {
        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        effect = "Allow"
        resources = [ "*" ]
        sid = "CreateCloudWatchLogs"
    }
}
 
resource aws_iam_policy cloudwatch {
    name = "${local.prefix}-cloudwatch-policy"
    path = "/"
    policy = data.aws_iam_policy_document.cloudwatch.json
}