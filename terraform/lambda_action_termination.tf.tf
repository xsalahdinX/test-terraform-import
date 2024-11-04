data "aws_iam_policy_document" "aws_lambda_termination_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "lambda_termination_policy" {
  name   = var.lambda_termination_policy_name
  path   = "/"
  policy = templatefile("./policies/lambda_termination_policy.json.tpl", { account_id = var.account_id, launch_template_iam_role_name = var.launch_template_iam_role_name, aws_cloudwatch_log_group_termination_prefix = var.aws_cloudwatch_log_group_termination_prefix, region = var.region })
  tags   = merge({ Name = var.lambda_termination_policy_name }, var.tags)

}
resource "aws_iam_role" "lambda_termination_role" {
  name               = var.lambda_termination_role_name
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.aws_lambda_termination_assume_role_policy.json
  tags               = merge({ Name = var.lambda_termination_role_name }, var.tags)
}

resource "aws_iam_role_policy_attachment" "lambda_termination_role_policy_attachment" {
  role       = aws_iam_role.lambda_termination_role.name
  policy_arn = aws_iam_policy.lambda_termination_policy.arn

}
resource "aws_cloudwatch_log_group" "actions_termination_log_group" {
  name              = var.aws_cloudwatch_log_group_termination_prefix
  retention_in_days = 0
  tags = {
    Confidentiality = "C2"
  }
}
data "archive_file" "termination_lambda_package" {
  type        = "zip"
  source_file = "./python/lambda_termination_function.py"
  output_path = "lambda_termination_function_payload.zip"
}

resource "aws_lambda_function" "github_actions_termination" {
  function_name                  = var.lambda_termination_name
  architectures                  = ["x86_64"]
  runtime                        = "python3.12"
  handler                        = "lambda_function.lambda_handler"
  filename                       = "lambda_termination_function_payload.zip"
  memory_size                    = 128
  timeout                        = 900
  role                           = aws_iam_role.lambda_termination_role.arn
  package_type                   = "Zip"
  reserved_concurrent_executions = -1
  skip_destroy                   = false
  source_code_hash               = data.archive_file.termination_lambda_package.output_base64sha256
  tags                           = merge({ Name = var.lambda_termination_name }, var.tags)
  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      DEBUG        = "true"
      GITHUB_TOKEN = "ghp_sdfsdf"
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = var.aws_cloudwatch_log_group_termination_prefix
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_termination_role_policy_attachment
  ]
}

resource "aws_lambda_permission" "apigateway_lambda_termination_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_actions_termination.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.default.execution_arn}/*/POST/${var.terminate_path}"

  depends_on = [
    aws_lambda_function.github_actions_termination
  ]
}

# resource "aws_lambda_invocation" "aws_lambda_termination_invocation" {
#   function_name = aws_lambda_function.github_actions_termination.function_name
#   input = jsonencode({
#     key1 = "value1"
#     key2 = "value2"
#   })

#   depends_on = [
#     aws_lambda_permission.apigateway_lambda_termination_permission
#   ]
# }
