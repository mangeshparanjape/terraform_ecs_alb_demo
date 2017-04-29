
####################################################################################################################
# From other modules / through main.tf as parameters
#
variable "name" {description = "The ECS cluster name"}
variable "environment" {description = "Environment tag"}
variable "key_name" {}
variable "vpc_id" {}
variable "subnets" {type = "list"}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "ssh_from_bastion_sg_id" {}
variable "web_access_from_nat_sg_id" {}
variable "lb_sg_id" {}
variable "instance_sg_id" {}
variable "vpc_cidr_block" {}

variable "region" {}

variable "instance_type" {}

variable "ecs_amis" {
	type="map"
}

variable "image" {}

variable "availability_zones" {
	type="list"
}

variable "instance_ebs_optimized" {}

variable "min_size" {}

variable "max_size" {}

variable "desired_capacity" {}

variable "associate_public_ip_address" {}

variable "root_volume_size" {}

variable "docker_volume_size" {}

####################################################################################################################