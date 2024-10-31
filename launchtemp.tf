#launch template iam role & policy & instance profile

data "aws_iam_policy_document" "aws_launch_template_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "coder_policy" {
  name   = "coder_policy"
  path   = "/"
  policy = file("./coder_policy.json")
}

resource "aws_iam_role" "action_instance" {
  name                  = "self-hosted-runner-role"
  description           = "self-hosted-runner-role"
  path                  = "/"
  assume_role_policy = data.aws_iam_policy_document.aws_launch_template_instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment1" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment2" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment3" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment4" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment5" {
  role       = aws_iam_role.action_instance.name
  policy_arn = aws_iam_policy.coder_policy.arn

}


resource "aws_iam_instance_profile" "action_instance_profile" {
  name        = "action-self-hosted-runner-instance-profile"
  path        = "/"
  role        = aws_iam_role.action_instance.name
}

# security group configuration

resource "aws_security_group" "action_sg" {
  name               = "action-self-hosted-runner-SG"
  description        = "action-self-hosted-runner-sg"
  vpc_id             = "vpc-07d665334c788078d"

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow outbound connections anywhere"
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow SSH inbound from anywhere"
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
  }]

  tags = {
    Confidentiality   = "C2"
    Environment       = "Dev"
  }

}

# launch template configuration

resource "aws_launch_template" "web" {
  default_version                      = 4
  name                                 = "github-actions-ubuntu-template"
  description                          = "github-actions-runner-launch-template"
  image_id                             = "ami-06b21ccaeff8cd686"
  instance_type                        = "t3.medium"
  user_data                            = filebase64("./example.sh")

  tags = {
    Confidentiality   = "C2"
  }
  hibernation_options {
    configured = true
  }
  iam_instance_profile {
    arn  = aws_iam_instance_profile.action_instance_profile.arn
    }
  network_interfaces {
    security_groups              = [aws_security_group.action_sg.id] #p
    subnet_id                    = "subnet-0e5b44bb0205a17de" #private subnet
  }
  tag_specifications {
    resource_type = "instance"
  }
}
