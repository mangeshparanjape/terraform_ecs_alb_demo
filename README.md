# Overview
Terraform ECS ALB Demo

# Prepare 
1. Create AWS key pair using console or cli. this key will be used t launch EC2 instances

2. Create a file named terraform.tfvars with the following contents and assign variables within this file:

    access_key = "Your AWS access key"
  
    secret_key = "Your AWS secret key"
  
    key_name = "AWS key pair name." #actual key file should be placed in the root directory."
  

# Launching
1. terraform get
2. terraform plan
3. terraform apply

# Destroying
terraform destroy

#Note:
Launching this stack will cost you some money.


