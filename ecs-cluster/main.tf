data "aws_ami" "ecs" {
    most_recent = true
    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
    filter {
        name = "name"
        values = ["${var.image}"]
    }
}

data "template_file" "userdata" {
    template = "${file("${path.module}/files/userdata.yml")}"
    vars {
        ecs_cluster = "${aws_ecs_cluster.main.name}"
    }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
    name = "${var.name}"

    lifecycle {
        create_before_destroy = true
    }
}

# Launch Config
resource "aws_launch_configuration" "lc" {
    name_prefix = "${var.name}-lc-"
    image_id = "${data.aws_ami.ecs.image_id}"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.ecs.id}", 
	"${var.ssh_from_bastion_sg_id}",
    "${var.web_access_from_nat_sg_id}",
	"${var.instance_sg_id}"]
    iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
    key_name = "${var.key_name}"
    associate_public_ip_address = false
    user_data = "${data.template_file.userdata.rendered}"

    lifecycle {
        create_before_destroy = true
    }
}

# Auto scaling Group
resource "aws_autoscaling_group" "main" {
    name = "${var.name}-asg"
    availability_zones = ["${var.availability_zones}"]
    vpc_zone_identifier = ["${join(",", var.subnets)}"]
    launch_configuration = "${aws_launch_configuration.lc.name}"
    min_size = 1
    max_size = 2

    lifecycle {
        create_before_destroy = true
    }
	
	tag {
		key   = "Name"
		value = "asg_ecs_ec2"
		propagate_at_launch = true
  }
}

# Security Group
resource "aws_security_group" "ecs" {
    name = "${var.name}"
    description = "ECS Cluster Security Group"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vpc-in" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["${var.vpc_cidr_block}"]
  security_group_id = "${aws_security_group.ecs.id}"
}


# IAM

resource "aws_iam_role" "ecs" {
  name = "ecs-role-${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs" {
  name = "ecs-instance-role-${var.name}-${var.environment}"
  role = "${aws_iam_role.ecs.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecs:StartTask",
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs" {
  name  = "ecs-instance-profile-${var.name}-${var.environment}"
  path  = "/"
  roles = ["${aws_iam_role.ecs.name}"]
}

output "id" {
  value = "${aws_ecs_cluster.main.id}"
}

