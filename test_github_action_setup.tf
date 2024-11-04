module "test_github_action_setup" {
  source = "./terraform"

  api_gateway_name                            = "test-github-actions-handler-rest-api"
  aws_api_gateway_deployment                  = "dev"
  terminate_path                              = "termination"
  webhook_path                                = "webhook"

  lambda_handler_policy_name                  = "lambda_handler_policy"
  lambda_handler_role_name                    = "github-actions-lambda-handler-role"
  aws_cloudwatch_log_group_handler_prefix     = "/aws/lambda/github-actions-job-handler"
  lambda_handler_name                         = "github-actions-job-handler"
  lambda_termination_policy_name              = "lambda_termination_policy"
  lambda_termination_role_name                = "github-actions-lambda-termination-role"
  aws_cloudwatch_log_group_termination_prefix = "/aws/lambda/github-actions-termination-fn"
  lambda_termination_name                     = "github-actions-termination-fn"

  launch_template_iam_policy_name             = "launch_template_iam_policy"
  launch_template_iam_role_name               = "self-hosted-runner-role"
  launch_template_instance_profile_name       = "action-self-hosted-runner-instance-profile"
  launch_template_sg_name                     = "action-self-hosted-runner-SG"
  launch_template_name                        = "github-actions-ubuntu-template"
  launch_template_instance_type               = "t3.medium"
  launch_template_ami_id                      = "ami-06b21ccaeff8cd686"
  launch_template_subnet_id                   = "subnet-0aa85c4e6373475bb"
  launch_template_root_device_name            = "/dev/xvda"
  launch_template_root_device_kms_key_id      = "arn:aws:kms:us-east-1:637423340153:key/a7efc8c0-2981-41ac-87f2-7d7d32286cb7"

  autoscaling_group_name                      = "github-actions-runner-asg"
  autoscaling_group_subnet_ids                = ["subnet-077dd5ef688fab8c8", "subnet-0aa85c4e6373475bb"] #private subnets
  security_group_vpc_id                       = "vpc-073562b4eaf0a57df"

  account_id                                  = "905418196748"
  region                                      = var.region


}