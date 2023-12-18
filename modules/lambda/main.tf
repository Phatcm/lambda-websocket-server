#Lambda_role
resource "aws_iam_role" "ws_messenger_lambda_role" {
  name = "wsMessage_lambda"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policies" {
  for_each = toset(["arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"])

  role = aws_iam_role.ws_messenger_lambda_role.name
  policy_arn = each.value
}

#Lambda
data "archive_file" "lambda_zip" {
  type = "zip"
  #output_path = "lambda_function_payload.zip"
  #source_dir = "./resources/"
  output_path = var.output_path
  source_dir = var.source_dir
}

resource "aws_lambda_function" "lambda_function" {
    #filename = "lambda_function_payload.zip"
    filename = var.filename
    function_name = var.lambda_function_name
    role = aws_iam_role.ws_messenger_lambda_role.arn

    handler = var.lambda_handler
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    runtime = var.lambda_runtime

    timeout = 500
}