####################################################################################################################
# From other modules / through main.tf as parameters
#
variable "name" {description = "The ECS cluster name"}
variable "environment" {description = "Environment tag"}
variable "key_name" {}
variable "vpc_id" {}
variable "private_subnets" {type = "list"}
variable "public_subnets" {
type = "list"
}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "ssh_from_bastion_sg_id" {}
variable "web_access_from_nat_sg_id" {}
variable "lb_sg_id" {}
variable "instance_sg_id" {}
variable "cluster_id" {}

variable "aws_region" {}
####################################################################################################################