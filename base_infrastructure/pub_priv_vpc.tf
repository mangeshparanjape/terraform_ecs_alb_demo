# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file
# except in compliance with the License. A copy of the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under the License.

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
resource "aws_instance" "nat" {
  ami = "${lookup(var.nat_amis, var.region)}" #"ami-184dc970" # this is a special ami preconfigured to do NAT
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.nat.id}"]
  subnet_id = "${element(aws_subnet.public_sn.*.id, 0)}"
  associate_public_ip_address = true
  source_dest_check = false
  tags {
      Name = "nat_ec2"
  }
}

resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc = true

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

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.default.id}"
  route {
      cidr_block = "0.0.0.0/0"
      instance_id = "${aws_instance.nat.id}"
  }
  count = "${length(var.private_subnet_cidr)}"
  tags {
      Name = "private_subnet_route_table"
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id = "${element(aws_subnet.private_sn.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private_rt.*.id, count.index)}"
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