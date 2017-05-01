
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
      Name = "terraform_vpc"
  }
}

output "vpc_cidr_block" {
  value = "${aws_vpc.default.cidr_block}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
      Name = "terraform_igw"
  }
}
output "vpc_id" {
  value = "${aws_vpc.default.id}"
}

#
# NAT Instance
#
#resource "aws_instance" "nat" {
#  ami = "${lookup(var.nat_amis, var.region)}" #"ami-184dc970" # this is a special ami preconfigured to do NAT
#  availability_zone = "${element(var.availability_zones, count.index)}"
#  instance_type = "${var.instance_type}"
#  key_name = "${var.key_name}"
#  security_groups = ["${aws_security_group.nat.id}"]
#  subnet_id = "${element(aws_subnet.public_sn.*.id, count.index)}"
#  associate_public_ip_address = true
#  source_dest_check = false
#  tags {
#      Name = "nat_ec2"
#  }
#  count = "${length(var.private_subnet_cidr)}"
#}

#resource "aws_eip" "nat" {
#  instance = "${element(aws_instance.nat.*.id, count.index)}"
#  vpc = true
#  count = "${length(var.private_subnet_cidr)}"	
#}

#NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public_sn.*.id, count.index)}"
  count = "${length(var.public_subnet_cidr)}"
  
  depends_on = [
    "aws_internet_gateway.default"
  ]	
}

resource "aws_eip" "nat" {
  vpc = true
  count = "${length(var.public_subnet_cidr)}"
	
  depends_on = [
    "aws_internet_gateway.default"
  ]	
}

resource "aws_instance" "bastion" {
  ami = "${lookup(var.bastion_amis, var.region)}" #"ami-60b6c60a"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  subnet_id = "${element(aws_subnet.public_sn.*.id, 0)}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.bastion_ssh_sg.id}"]
  key_name = "${var.key_name}"
  
  tags {
    Name = "bastion_ec2"
  }
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}


#
# Public Subnet
#
resource "aws_subnet" "public_sn" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${element(var.public_subnet_cidr, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  count = "${length(var.public_subnet_cidr)}"
  tags {
      Name = "public_subnet"
  }
}
output "public_subnet_id" {
  value = "${element(aws_subnet.public_sn.*.id, 0)}"
}

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.default.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.default.id}"
  }
  count = "${length(var.public_subnet_cidr)}"
  tags {
      Name = "public_subnet_route_table"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id = "${element(aws_subnet.public_sn.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public_rt.*.id, count.index)}"
  count = "${length(var.public_subnet_cidr)}"
}

#
# Private Subnet
#
resource "aws_subnet" "private_sn" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${element(var.private_subnet_cidr, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  count = "${length(var.private_subnet_cidr)}"
  tags {
      Name = "private_subnet"
  }
}
output "private_subnet_id" {
  value = "${element(aws_subnet.private_sn.*.id, 0)}"
}

#NAT instance route
#resource "aws_route_table" "private_rt" {
#  vpc_id = "${aws_vpc.default.id}"
#  route {
#      cidr_block = "0.0.0.0/0"
#      instance_id = "${element(aws_instance.nat.*.id, count.index)}"
#  }
#  count = "${length(var.private_subnet_cidr)}"
#  tags {
#      Name = "private_subnet_route_table"
#  }
#}


#NAT gateway route
resource "aws_route_table" "private_rt_tbl" {
  vpc_id = "${aws_vpc.default.id}"
  count = "${length(var.public_subnet_cidr)}"
  tags {
      Name = "private_subnet_route_table"
  }
}

resource "aws_route" "private_rt" {
  route_table_id            = "${element(aws_route_table.private_rt_tbl.*.id, count.index)}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id 			= "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"
  count = "${length(var.public_subnet_cidr)}"
}


resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id = "${element(aws_subnet.private_sn.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private_rt_tbl.*.id, count.index)}"
  count = "${length(var.private_subnet_cidr)}"
}


output "availability_zones" {
	value = "${var.availability_zones}"
}

output "public_availability_zones" {
	value = ["${aws_subnet.public_sn.*.availability_zone}"]	
}

output "private_availability_zones" {
	value = ["${aws_subnet.private_sn.*.availability_zone}"]	
}

output "public_subnets" {
	value = ["${aws_subnet.public_sn.*.id}"]
}

output "private_subnets" {
	value = ["${aws_subnet.private_sn.*.id}"]
}