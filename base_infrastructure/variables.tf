
variable "ip_range" {}

variable "availability_zones" {
	type="list"
}

variable "vpc_cidr" {}

variable "public_subnet_cidr" {
	type="list"
}

variable "private_subnet_cidr" {
	type="list"
}

variable "key_name" {}

variable "nat_amis" {
	type="map"
}

variable "bastion_amis" {
	type="map"
}

variable "instance_type" {}

variable "region" {}