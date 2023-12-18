# lambda-websocket-server
Automate the provision of server infrastructure for lambda websocket online chat project

## Installation Guide
Required: 
 - Python 3.9, Terraform, VSCode installed
 - AWS CLI install and profile configure
 - Edit aws credential information in terraform.tfvars (important)

Provision infrastructure in AWS with terraform:
```
terraform init
```
```
terraform apply
```

Run the front-end in: https://github.com/Phatcm/lambda-websocket-client.git
