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

variable "accesskey" {}

variable "secretkey" {}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type = "list"
	description = "List of public subnets"
	default = ["10.20.20.0/24", "10.20.21.0/24"]
}
variable "private_subnet_cidr" {
  description = "List of private subnets"
	type = "list"
	default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "region" {
  default = "us-east-1"
}
variable "ip_range" {
  default = "0.0.0.0/0" # Change to your IP Range!
}
variable "availability_zones" {
  # No spaces allowed between az names!
  default = ["us-east-1a","us-east-1b"]
}
variable "key_name" {}

variable "instance_type" {
  default = "t2.small"
}
variable "asg_min" {
  default = "1"
}
variable "asg_max" {
  default = "1"
}
variable "asg_desired" {
  default = "1"
}
# Amazon Linux AMI
# ECS optimized
variable "ecs_amis" {
  default = {
    us-east-1 = "ami-1924770e"
  }
}

variable "image" {
  description = "AMI Image ID"
  default = "amzn-ami-2016.09.a-amazon-ecs-optimized"
}

variable "nat_amis" {
	default = {
		us-east-1 ="ami-184dc970"
	}
}

variable "bastion_amis" {
  default = {
    us-east-1 = "ami-60b6c60a"
  }
}


variable "instance_ebs_optimized" {
  description = "When set to true the instance will be launched with EBS optimized turned on"
  default     = true
}

variable "associate_public_ip_address" {
  description = "Should created instances be publicly accessible (if the SG allows)"
  default = false
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  default     = 25
}

variable "docker_volume_size" {
  description = "Attached EBS volume size in GB"
  default     = 25
}