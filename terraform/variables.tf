variable "api_gateway_name" {
  description = "The name of the API Gateway"
  type        = string
}
variable "aws_api_gateway_deployment" {
  description = "The name of the API Gateway deployment"
  type        = string

}

variable "terminate_path" {
  description = "The path to terminate the API Gateway"
  type        = string
}
variable "webhook_path" {
  description = "The path to the webhook"
  type        = string

}

variable "lambda_handler_policy_name" {
  description = "The name of the lambda handler function"
  type        = string

}

variable "lambda_handler_role_name" {
  description = "The name of the lambda handler IAM role"
  type        = string

}

variable "aws_cloudwatch_log_group_handler_prefix" {
  description = "The name of the cloudwatch log group"
  type        = string

}

variable "lambda_handler_name" {
  description = "The name of the lambda handler"
  type        = string

}

variable "lambda_termination_policy_name" {
  description = "The name of the lambda termination policy"
  type        = string

}

variable "lambda_termination_role_name" {
  description = "The name of the lambda termination role"
  type        = string

}

variable "aws_cloudwatch_log_group_termination_prefix" {
  description = "The name of the cloudwatch log group for the termination function"
  type        = string

}

variable "lambda_termination_name" {
  description = "The name of the lambda termination function"
  type        = string

}

variable "launch_template_iam_policy_name" {
  description = "The name of the launch template IAM policy"
  type        = string

}

variable "launch_template_iam_role_name" {
  description = "The name of the launch template IAM role"
  type        = string

}

variable "launch_template_instance_profile_name" {
  description = "The name of the launch template instance profile"
  type        = string

}

variable "launch_template_sg_name" {
  description = "The name of the launch template security group"
  type        = string

}

variable "launch_template_name" {
  description = "The name of the launch template"
  type        = string

}

variable "launch_template_ami_id" {
  description = "The AMI ID for the launch template"
  type        = string

}

variable "launch_template_instance_type" {
  description = "The instance type for the launch template"
  type        = string

}

variable "launch_template_subnet_id" {
  description = "The subnet ID for the launch template"
  type        = string

}

variable "autoscaling_group_name" {
  description = "The name of the autoscaling group"
  type        = string

}

variable "autoscaling_group_subnet_ids" {
  description = "The subnet IDs for the autoscaling group"
  type        = list(string)

}

variable "security_group_vpc_id" {
  description = "The VPC ID for the security group"
  type        = string
  
}























variable "access_key" {
  description = " from terraform cloud"
  type        = string

}

variable "secret_key" {
  description = " from terraform cloud"
  type        = string

}

variable "region" {
  description = " from terraform cloud"
  type        = string

}
