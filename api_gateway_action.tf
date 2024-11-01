
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

# models

resource "aws_api_gateway_model" "workflowJobCompletedModel" {
  content_type = "application/json"
  description  = "webhook example of workflow Job Queued"
  name         = "workflowJobCompletedModel"
  rest_api_id  = aws_api_gateway_rest_api.default.id
  schema = file("./models/workflowJobCompletedModel.json")
}

resource "aws_api_gateway_model" "workflowJobQueuedModel" {
  content_type = "application/json"
  description  = "webhook example of workflow Job Queued"
  name         = "workflowJobQueuedModel"
  rest_api_id  = aws_api_gateway_rest_api.default.id
  schema = file("./models/workflowJobQueuedModel.json")
}

resource "aws_api_gateway_model" "workflowRunRequestedModel" {
  content_type = "application/json"
  description  = "webhook example of workflow Job Queued"
  name         = "workflowRunRequestedModel"
  rest_api_id  = aws_api_gateway_rest_api.default.id
  schema = file("./models/workflowRunRequestedModel.json")
}


# termination_resource

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
depends_on = [ aws_api_gateway_model.workflowJobCompletedModel ] 
}




resource "aws_api_gateway_integration" "termination_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.termination_resource.id
  http_method             = aws_api_gateway_method.termination_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri = aws_lambda_function.github_actions_termination.invoke_arn
}

resource "aws_api_gateway_method_response" "termination_method_response" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.termination_resource.id
  http_method = aws_api_gateway_method.termination_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
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


# webhook_resource


resource "aws_api_gateway_resource" "webhook_resource" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "webhook"

}

resource "aws_api_gateway_method" "webhook_method" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_validator_id = aws_api_gateway_request_validator.default.id

  request_models = {
    "application/json" = "workflowJobQueuedModel"
  }
  request_parameters = {
    "method.request.header.X-GitHub-Enterprise-Host" = true
  }
depends_on = [ aws_api_gateway_model.workflowJobQueuedModel ] 
}



resource "aws_api_gateway_integration" "webhook_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.webhook_resource.id
  http_method             = aws_api_gateway_method.webhook_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = aws_lambda_function.actions_handler_lambda_function.invoke_arn

}

resource "aws_api_gateway_method_response" "webhook_method_response" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.webhook_resource.id
  http_method = aws_api_gateway_method.webhook_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "webhook_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.termination_resource.id
  http_method = aws_api_gateway_method.termination_method.http_method
  status_code = aws_api_gateway_method_response.termination_method_response.status_code

  depends_on = [
    aws_api_gateway_method.webhook_method,
    aws_api_gateway_integration.webhook_lambda_integration
  ]
}




# deployment and stage

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.termination_lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name = "dev"
}
