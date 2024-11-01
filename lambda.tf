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
  name   = "lambda_termination_policy"
  path   = "/"
  policy = file("./lambda_termination_policy.json")
}
resource "aws_iam_role" "lambda_termination_role" {
  name                  = "github-actions-lambda-termination-role"
  path                  = "/service-role/"
  assume_role_policy    = data.aws_iam_policy_document.aws_lambda_termination_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_termination_role_policy_attachment" {
  role       = aws_iam_role.lambda_termination_role.name
  policy_arn = aws_iam_policy.lambda_termination_policy.arn

}
data "archive_file" "termination_lambda_package" {
  type        = "zip"
  source_file = "lambda_termination_function.py"
  output_path = "lambda_termination_function_payload.zip"
}

resource "aws_lambda_function" "github_actions_termination" {
  function_name                      = "github-actions-termination-fn"
  architectures                      = ["x86_64"]
  runtime                            = "python3.12"
  handler                            = "lambda_function.lambda_handler"
  filename                           = "lambda_termination_function_payload.zip"
  memory_size                        = 128
  timeout                            = 900
  role                               = aws_iam_role.lambda_termination_role.arn
  package_type                       = "Zip"
  reserved_concurrent_executions     = -1
  skip_destroy                       = false

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
    log_group             = "/aws/lambda/github-actions-termination-fn"
  }

  tracing_config {
    mode = "PassThrough"
  }
}
