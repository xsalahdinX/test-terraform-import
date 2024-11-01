data "aws_iam_policy_document" "aws_lambda_handler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "lambda_handler_policy" {
  name   = "lambda_handler_policy"
  path   = "/"
  policy = file("./policies/lambda_handler_policy.json")
}
resource "aws_iam_role" "lambda_handler_role" {
  name                  = "github-actions-lambda-handler-role"
  path                  = "/service-role/"
  assume_role_policy    = data.aws_iam_policy_document.aws_lambda_handler_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_handler_role_policy_attachment" {
  role       = aws_iam_role.lambda_handler_role.name
  policy_arn = aws_iam_policy.lambda_handler_policy.arn

}

resource "aws_cloudwatch_log_group" "actions_handler_log_group" {
  name              = "/aws/lambda/github-actions-job-handler"
  retention_in_days = 14
  tags = {
    Confidentiality = "C2"
  }
}

data "archive_file" "handler_lambda_package" {
  type        = "zip"
  source_file = "./python/lambda_handler_function.py"
  output_path = "lambda_handler_function_payload.zip"
}

resource "aws_lambda_function" "actions_handler_lambda_function" {
  function_name                      = "github-actions-job-handler"
  architectures                      = ["x86_64"]
  runtime                            = "python3.11"
  handler                            = "lambda_function.lambda_handler"
  filename                           = "lambda_handler_function_payload.zip"
  memory_size                        = 128
  timeout                            = 3
  role                               = aws_iam_role.lambda_handler_role.arn
  package_type                       = "Zip"
  reserved_concurrent_executions     = -1
  skip_destroy                       = false
  source_code_hash                   = data.archive_file.handler_lambda_package.output_base64sha256
  ephemeral_storage {
    size = 512
  }

  tags = {
    Confidentiality   = "C2"
  }

  environment {
    variables = {
      DEBUG        = "true"
      GITHUB_TOKEN = "ghp_sdfsdf"
    }
  }

  logging_config {
    log_format            = "Text"
    log_group             = "/aws/lambda/github-actions-job-handler"
  }

  tracing_config {
    mode = "PassThrough"
  }

}

resource "aws_lambda_permission" "apigateway_lambda_handler_permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.actions_handler_lambda_function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/POST/webhook"

  depends_on = [
    aws_lambda_function.actions_handler_lambda_function
  ]
}

# resource "aws_lambda_invocation" "aws_lambda_handler_invocation" {
#   function_name = aws_lambda_function.actions_handler_lambda_function.function_name
#   input = jsonencode({
#     key1 = "value1"
#     key2 = "value2"
#   })

#   depends_on = [
#     aws_lambda_permission.apigateway_lambda_handler_permission
#   ]
# }

