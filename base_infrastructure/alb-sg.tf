### Security

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = "${aws_vpc.default.id}"
  name   = "ecs-lb_sg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  
  tags {
	Name = "ecs-lb_sg"
  }
}

output "lb_sg_id" {
  value = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group" "instance_sg" {
  description = "controls direct access to application instances"
  vpc_id      = "${aws_vpc.default.id}"
  name        = "ecs-instance_sg"

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    security_groups = [
      "${aws_security_group.lb_sg.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
	Name = "ecs-instance_sg"
  }
}

output "instance_sg_id" {
  value = "${aws_security_group.instance_sg.id}"
}