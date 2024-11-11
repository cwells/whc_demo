resource "aws_apigatewayv2_api" "whc" {
	name = "whc"
	protocol_type = "HTTP"
  target = aws_lambda_function.whc.arn

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "HEAD", "OPTIONS", "PATCH", "POST" ,"PUT"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
  }
}

resource "aws_lambda_permission" "whc" {
	action = "lambda:InvokeFunction"
	function_name = aws_lambda_function.whc.arn
	principal = "apigateway.amazonaws.com"

	source_arn = "${aws_apigatewayv2_api.whc.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "whc-apigw" {
    name = "cloudwatch-log-${local.prefix}-apigw-${var.stage}"

    tags = {
        Environment = var.stage
        Application = "${local.prefix}-apigw"
    }
}

output "gateway_id" {
  value = "${aws_apigatewayv2_api.whc.api_endpoint}/dev/"
}
