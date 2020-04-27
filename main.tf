/******************************************************************************
* DATA SOURCES
*******************************************************************************/

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

/******************************************************************************
* LAUNCH CONFIGURATION
*******************************************************************************/

resource "aws_launch_configuration" "this" {
  name_prefix                 = var.name
  image_id                    = var.ami_id
  instance_type               = "t2.micro"
  iam_instance_profile        = var.iam_instance_profile
  security_groups             = [aws_security_group.utility_app.id]
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = local.user_data
  enable_monitoring           = var.enable_monitoring

  lifecycle {
    create_before_destroy = true
  }
}

/******************************************************************************
* AUTO SCALING GROUP
*******************************************************************************/

resource "aws_autoscaling_group" "this" {
  name_prefix          = "${coalesce(var.asg_name, var.name)}-"
  launch_configuration = aws_launch_configuration.this.name
  max_size             = 5
  min_size             = 3
  desired_capacity     = 3
  vpc_zone_identifier  = data.aws_subnet_ids.all.ids
  target_group_arns    = [aws_lb_target_group.this.arn]

  health_check_grace_period = 300
  health_check_type         = "EC2"
  default_cooldown          = 300
  force_delete              = false
  termination_policies      = ["Default"]
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = "1Minute"
  wait_for_capacity_timeout = 0
  protect_from_scale_in     = false
  depends_on                = [aws_lb.this]

  tags = [
    {
      key                 = "Environment"
      value               = "Development"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "Utility-App"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "this" {
  name                   = join("-",[var.name, "scale-out"])
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  target_tracking_configuration {
  predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_autoscaling_notification" "this" {
  group_names = [
    "${aws_autoscaling_group.this.name}"
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${aws_sns_topic.this.arn}"
}

resource "aws_sns_topic" "this" {
  name = join("-",[var.name, "scale-out"])

  # arn is an exported attribute
}

/******************************************************************************
* LOAD BALANCER
*******************************************************************************/

resource "aws_lb" "this" {
  name               = join("-",[var.name, "alb"])
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [data.aws_security_group.default.id]

  tags = {
    Name        = join("-",[var.name, "alb"])
    Owner       = "DevOps"
    Environment = "Development"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group" "this" {
  name     = join("-",[var.name, "lb-tg"])
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# resource "aws_lb_target_group_attachment" "this" {
#   target_group_arn = aws_lb_target_group.this.arn
#   target_id        = aws_instance.this.id
#   port             = 80
# }

/******************************************************************************
* SECURITY GROUP
*******************************************************************************/

resource "aws_security_group" "utility_app_alb" {
  name = "utility-app-alb"

  ingress {
    description = "Allow HTTP access from anywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "Allow access from Utility-App"
  #   protocol        = "tcp"
  #   from_port       = 0
  #   to_port         = 65535
  #   security_groups = [aws_security_group.utility_app.id]
  # }

  egress {
    description = "Allow outbound traffic to anywhere"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "utility_app" {
  name = var.name

  ingress {
    description = "Allow SSH access from anywhere"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow access from Utility-App Load Balancer"
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = [aws_security_group.utility_app_alb.id]
  }

  ingress {
    description = "Allow HTTP access from anywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to anywhere"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}