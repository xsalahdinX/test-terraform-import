{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:*",
                "ec2:*",
                "autoscaling:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:${region}:${account_id}:*",
                "arn:aws:iam::${account_id}:role/${launch_template_iam_role_name}"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${region}:${account_id}:log-group:${aws_cloudwatch_log_group_termination_prefix}:*"
        }
    ]
}