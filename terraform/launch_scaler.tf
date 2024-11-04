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
  name   = var.launch_template_iam_policy_name
  path   = "/"
  policy = file("./policies/coder_policy.json")
}

resource "aws_iam_role" "action_instance" {
  name               = var.launch_template_iam_role_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.aws_launch_template_instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_AmazonS3FullAccess" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment_AutoScalingFullAccess" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment_ReadOnlyAccess" {
  role       = aws_iam_role.action_instance.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_coder_policy" {
  role       = aws_iam_role.action_instance.name
  policy_arn = aws_iam_policy.coder_policy.arn

}


resource "aws_iam_instance_profile" "action_instance_profile" {
  name = var.launch_template_instance_profile_name
  path = "/"
  role = aws_iam_role.action_instance.name
}

# security group configuration

resource "aws_security_group" "action_sg" {
  name        = var.launch_template_sg_name
  description = "action-self-hosted-runner-sg"
  vpc_id      = var.security_group_vpc_id


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
    Confidentiality = "C2"
    Environment     = "Dev"
  }

}

# launch template configuration

resource "aws_launch_template" "action_lanch_template" {
  name          = var.launch_template_name
  description   = "github-actions-runner-launch-template"
  image_id      = var.launch_template_ami_id
  instance_type = var.launch_template_instance_type
  user_data     = filebase64("./user_data/example.sh")

  tags = {
    Confidentiality = "C2"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
      volume_type = "gp2"
      delete_on_termination = true
      encrypted = true
      kms_key_id = "arn:aws:kms:us-east-1:637423340153:key/a7efc8c0-2981-41ac-87f2-7d7d32286cb7"
    }
  }

  hibernation_options {
    configured = true
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.action_instance_profile.arn
  }
  network_interfaces {
    security_groups = [aws_security_group.action_sg.id] #p
    subnet_id       = var.launch_template_subnet_id     #private subnet

  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Confidentiality   = "C2"
      Environment       = "DEV"
      ManagedBy         = "vssefunc.mailboxdeploymentcoe@vodafone.com"
      ManagementAccount = "242534911695"
      Name              = "github-actions-resources"
      Project           = "vois-coe"
      SecurityZone      = "I-A"
      TaggingVersion    = "V2.4"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Confidentiality   = "C2"
      Environment       = "DEV"
      ManagedBy         = "vssefunc.mailboxdeploymentcoe@vodafone.com"
      ManagementAccount = "242534911695"
      Name              = "github-actions-resources"
      Project           = "vois-coe"
      SecurityZone      = "I-A"
      TaggingVersion    = "V2.4"
    }
  }
}


# autoscaling group configuration

resource "aws_autoscaling_group" "action_asg" {
  name                      = var.autoscaling_group_name
  vpc_zone_identifier       = var.autoscaling_group_subnet_ids
  max_size                  = 2
  min_size                  = 0
  desired_capacity          = 0
  health_check_grace_period = 120
  health_check_type         = "EC2"
  default_cooldown          = 1
  default_instance_warmup   = 0
  protect_from_scale_in     = true

  launch_template {
    id = aws_launch_template.action_lanch_template.id
  }
  tag {
    key                 = "Confidentiality"
    propagate_at_launch = true
    value               = "C2"
  }
  warm_pool {
    max_group_prepared_capacity = -1
    min_size                    = 2
    pool_state                  = "Stopped"
    instance_reuse_policy {
      reuse_on_scale_in = false
    }
  }
}
