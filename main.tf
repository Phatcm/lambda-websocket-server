terraform {
  required_version = ">=1.0.0"
}

locals {
  name = var.project_name
}

provider "aws" {
  region = var.region
  profile = var.profile
}

module "lambda" {
  source = "./modules/lambda"
  lambda_function_name = var.lambda_uploader_function_name
  lambda_handler = var.lambda_handler
  lambda_runtime = var.lambda_runtime
  output_path = var.lambda_uploader_output_path
  source_dir = var.lambda_uploader_source_dir
  filename = var.lambda_uploader_filename
}

module "api_gateway" {
  source = "./modules/api_gateway"
  api_name = var.api_name
  lambda_function_name = module.lambda.lambda_function_name
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  lambda_function_arn = module.lambda.lambda_function_arn
}

output "api_invoke_url" {
    value = module.api_gateway.api_gateway_invoke_url
}