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
provider "aws" {
  region = "${var.region}"
  access_key = "${var.accesskey}"
  secret_key = "${var.secretkey}"
}

module "base" {
  source = "./base_infrastructure"
  key_name = "${var.key_name}"
  ip_range = "${var.ip_range}"
  availability_zones = "${var.availability_zones}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_cidr = "${var.public_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  nat_amis = "${var.nat_amis}"
  bastion_amis = "${var.bastion_amis}"
  instance_type = "${var.instance_type}"
  region = "${var.region}"
}

module "ecs" {
	source = "./ecs-cluster"	
	name = "focus-dev"
	environment = "dev"
	key_name = "${var.key_name}"
	vpc_id = "${module.base.vpc_id}"
	subnets = "${module.base.private_subnets}"
	public_subnet_id = "${module.base.public_subnet_id}"
	private_subnet_id = "${module.base.private_subnet_id}"
	ssh_from_bastion_sg_id = "${module.base.ssh_from_bastion_sg_id}"
	web_access_from_nat_sg_id = "${module.base.web_access_from_nat_sg_id}"
	lb_sg_id = "${module.base.lb_sg_id}"
	instance_sg_id = "${module.base.instance_sg_id}"
	vpc_cidr_block = "${module.base.vpc_cidr_block}"
	instance_type = "${var.instance_type}"
	ecs_amis = "${var.ecs_amis}"
	image = "${var.image}"
	availability_zones  = "${var.availability_zones}"
	instance_ebs_optimized = "${var.instance_ebs_optimized}"
	min_size = "${var.asg_min}"
	max_size = "${var.asg_max}"
	desired_capacity = "${var.asg_desired}"
	associate_public_ip_address = "${var.associate_public_ip_address}"
	root_volume_size = "${var.root_volume_size}"
	docker_volume_size = "${var.docker_volume_size}"
	region = "${var.region}"
}


module "ecs-service-alb" {
	source = "./ecs-service-alb"	
	name = "focus-dev-service"
	environment = "dev"
	key_name = "${var.key_name}"
	vpc_id = "${module.base.vpc_id}"
	private_subnets = "${module.base.private_subnets}"
	public_subnets = "${module.base.public_subnets}"
	public_subnet_id = "${module.base.public_subnet_id}"
	private_subnet_id = "${module.base.private_subnet_id}"
	ssh_from_bastion_sg_id = "${module.base.ssh_from_bastion_sg_id}"
	web_access_from_nat_sg_id = "${module.base.web_access_from_nat_sg_id}"
	lb_sg_id = "${module.base.lb_sg_id}"
	instance_sg_id = "${module.base.instance_sg_id}"
	cluster_id = "${module.ecs.id}"
	aws_region = "${var.region}"
}