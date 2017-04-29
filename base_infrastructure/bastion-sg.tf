resource "aws_security_group" "bastion_ssh_sg" {
  name = "bastion_ssh_sg"
  description = "Allow SSH to Bastion host from approved ranges"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ip_range}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"
  tags {
      Name = "bastion_ssh_sg"
  }
}
output "bastion_ssh_sg_id" {
  value = "${aws_security_group.bastion_ssh_sg.id}"
}

resource "aws_security_group" "ssh_from_bastion_sg" {
  name = "ssh_from_bastion_sg"
  description = "Allow SSH from Bastion host(s)"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.bastion_ssh_sg.id}",
      "${aws_security_group.nat.id}"
    ]
  }
  vpc_id = "${aws_vpc.default.id}"
  tags {
      Name = "ssh_from_bastion_sg"
  }
}
output "ssh_from_bastion_sg_id" {
  value = "${aws_security_group.ssh_from_bastion_sg.id}"
}
