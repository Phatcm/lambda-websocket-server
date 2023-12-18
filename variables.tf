#provider configure
variable "project_name" {
  type = string
  default = "my-project"
}

variable "region" {
  type = string
}

variable "profile" {
  type = string
}

#lambda uploader
variable "lambda_uploader_function_name" {
  type = string
}

variable "lambda_handler" {
  type = string
}

variable "lambda_runtime" {
  type = string
}

variable "lambda_uploader_output_path" {
  type = string
}

variable "lambda_uploader_source_dir" {
  type = string
}

variable "lambda_uploader_filename" {
  type = string
}


#api gateway configure
variable "api_name" {
  type = string
  default = "api_gateway"
}