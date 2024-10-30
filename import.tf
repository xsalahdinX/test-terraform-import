
resource "aws_api_gateway_rest_api" "default" {
  name              = "github-actions-handler-rest-api"
  description       = "This is the description of the API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_request_validator" "default" {
  name                        = "Validate body, query string parameters, and headers"
  rest_api_id                 = aws_api_gateway_rest_api.default.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "workflowJobQueuedModel" {
  content_type = "application/json"
  description  = "webhook example of workflow Job Queued"
  name         = "workflowJobQueuedModel"
  rest_api_id  = aws_api_gateway_rest_api.default.id
  schema = file("./workflowJobQueuedModel.js")
}

resource "aws_api_gateway_resource" "termination_resource" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "termination"

}

resource "aws_api_gateway_method" "termination_method" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.termination_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_validator_id = aws_api_gateway_request_validator.default.id
  # depoends on models
  request_models = {
    "application/json" = "workflowJobCompletedModel"
  }
  request_parameters = {
    "method.request.header.X-GitHub-Enterprise-Host" = false
  }
depends_on = [ aws_api_gateway_model.workflowJobQueuedModel ] 
}




resource "aws_api_gateway_integration" "termination_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.termination_resource.id
  http_method             = aws_api_gateway_method.termination_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  #after lmbda creations
  # uri = aws_lambda_function.html_lambda.invoke_arn
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:654654225119:function:cfst-1449-e3b2dff83c8e721fffb7950cf18-InitFunction-3G0DAqUCn87D/invocations"

}

resource "aws_api_gateway_method_response" "termination_method_response" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.termination_resource.id
  http_method = aws_api_gateway_method.termination_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "termination_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.termination_resource.id
  http_method = aws_api_gateway_method.termination_method.http_method
  status_code = aws_api_gateway_method_response.termination_method_response.status_code

  depends_on = [
    aws_api_gateway_method.termination_method,
    aws_api_gateway_integration.termination_lambda_integration
  ]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.termination_lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name = "dev"
}
