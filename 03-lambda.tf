resource aws_iam_role lambda {
    name = "${local.prefix}-lambda-role"
    assume_role_policy = jsonencode(
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Effect": "Allow"
                }
            ]
        }
    )
}

resource "aws_cloudwatch_log_group" "whc_lambda" {
    name = "cloudwatch-log-${local.prefix}-lambda-${var.stage}"

    tags = {
        Environment = var.stage
        Application = "${local.prefix}-lambda"
    }
}

resource aws_lambda_function whc {
    depends_on = [
        null_resource.ecr_image,
        aws_cloudwatch_log_group.whc_lambda
    ]
    function_name = "${local.prefix}-lambda"
    role = aws_iam_role.lambda.arn
    timeout = 30
    memory_size = 4096
    image_uri = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.lambda_image.id}"
    package_type = "Image"

    ephemeral_storage { size = 4096 }

    environment {
        variables = {
            STAGE = var.stage
        }
    }
}

 
output "lambda_name" {
    value = aws_lambda_function.whc.id
}
