
## ECS

#data "template_file" "task_definition" {
#  template = "${file("${path.module}/task-definition.json")}"
#
#  vars {
#    image_url        = "581383003481.dkr.ecr.us-east-1.amazonaws.com/focus-api:latest"
#    container_name   = "focus-api-container"
#    log_group_region = "${var.aws_region}"
#    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
#	 alb_dns_name	 = "${aws_alb.main.dns_name}"
#  }
#  
#  depends_on = [
#    "aws_alb.main"
#  ]
#}

data "template_file" "task_definition-product-api" {
  template = "${file("${path.module}/task-definition-product-api.json")}"

  vars {
    image_url        = "275396840892.dkr.ecr.us-east-1.amazonaws.com/ecs-refarch-cloudformation/product-service:1.0.0"
    container_name   = "product-api-container"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
  }
  
  depends_on = [
    "aws_alb.main"
  ]
}


#resource "aws_ecs_task_definition" "focus-api-task-definition" {
#  family                = "tf-focus-api-td"
#  container_definitions = "${data.template_file.task_definition.rendered}"
#}

resource "aws_ecs_task_definition" "product-api-task-definition" {
  family                = "tf-product-api-td"
  container_definitions = "${data.template_file.task_definition-product-api.rendered}"
}

#resource "aws_ecs_service" "focus-api-service" {
#  name            = "tf-focus-api-ecs"
#  cluster         = "${var.cluster_id}"
#  task_definition = "${aws_ecs_task_definition.focus-api-task-definition.arn}"
#  desired_count   = 1
#  iam_role        = "${aws_iam_role.ecs_service.name}"
#
#  load_balancer {
#    target_group_arn = "${aws_alb_target_group.focus-api-tg.id}"
#    container_name   = "focus-api-container"
#    container_port   = "30003"
#  }
#
#  depends_on = [
#    "aws_iam_role_policy.ecs_service",
#    "aws_alb_listener.front_end",
#  ]
#}

resource "aws_ecs_service" "product-api-service" {
  name            = "tf-product-api-ecs"
  cluster         = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.product-api-task-definition.arn}"
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.product-api-tg.id}"
    container_name   = "product-api-container"
    container_port   = "8001"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_alb_listener.front_end",
  ]
}

## IAM

resource "aws_iam_role" "ecs_service" {
  name = "ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },	
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "ecs_policy"
  role = "${aws_iam_role.ecs_service.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
  name  = "tf-ecs-instprofile"
  roles = ["${aws_iam_role.app_instance.name}"]
}

resource "aws_iam_role" "app_instance" {
  name = "ecs-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/instance-profile-policy.json")}"

  vars {
    app_log_group_arn = "${aws_cloudwatch_log_group.app.arn}"
    ecs_log_group_arn = "${aws_cloudwatch_log_group.ecs.arn}"
  }
}

resource "aws_iam_role_policy" "instance" {
  name   = "EcsInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

## ALB

#resource "aws_alb_target_group" "focus-api-tg" {
#  name     = "tf-focus-api-ecs"
#  port     = 80
#  protocol = "HTTP"
#  vpc_id   = "${var.vpc_id}"
#}

resource "aws_alb_target_group" "product-api-tg" {
  name     = "tf-product-api-ecs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  
  health_check {
	path = "/products"
  }
}

resource "aws_alb" "main" {
  name            = "alb-ecs"
  subnets         = ["${var.public_subnets}"]
  security_groups = ["${var.lb_sg_id}"]
}

#resource "aws_alb_listener" "front_end" {
#  load_balancer_arn = "${aws_alb.main.id}"
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    target_group_arn = "${aws_alb_target_group.focus-api-tg.id}"
#    type             = "forward"
#  }
#}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.product-api-tg.id}"
    type             = "forward"
  }
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-focus-api"
}
