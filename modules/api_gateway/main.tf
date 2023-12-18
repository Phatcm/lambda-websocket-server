data "aws_iam_policy_document" "ws_messenger_api_gateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = [var.lambda_function_arn]
  }
}

resource "aws_iam_policy" "ws_messenger_api_gateway_policy" {
  name   = "WsMessengerAPIGatewayPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_api_gateway_policy.json
}

resource "aws_iam_role" "ws_messenger_api_gateway_role" {
  name = "WsMessengerAPIGatewayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_messenger_api_gateway_policy.arn]
}

#api gateway
resource "aws_apigatewayv2_api" "ws_messenger_api_gateway" {
  name                       = var.api_name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "ws_messenger_api_integration" {
  api_id                    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_type          = "AWS_PROXY"
  integration_uri           = var.lambda_invoke_arn
  credentials_arn           = aws_iam_role.ws_messenger_api_gateway_role.arn 
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration_response" "ws_messenger_api_integration_response" {
  api_id                   = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_id           = aws_apigatewayv2_integration.ws_messenger_api_integration.id
  integration_response_key = "/200/"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_default_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_connect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_disconnect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}


resource "aws_apigatewayv2_route" "ws_messenger_api_setname_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "setName"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}


#sendPublic
resource "aws_apigatewayv2_route" "ws_messenger_api_sendpublic_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "sendPublic"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

#sendPrivate
resource "aws_apigatewayv2_route" "ws_messenger_api_sendprivate_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "sendPrivate"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

#deployment
resource "aws_apigatewayv2_deployment" "ws_messenger_deployment" {
  api_id       = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_integration.ws_messenger_api_integration.id,
      aws_apigatewayv2_route.ws_messenger_api_connect_route.id,
      aws_apigatewayv2_route.ws_messenger_api_disconnect_route.id,
      aws_apigatewayv2_route.ws_messenger_api_default_route.id,
      aws_apigatewayv2_route.ws_messenger_api_setname_route.id,
      aws_apigatewayv2_route.ws_messenger_api_sendpublic_route.id,
      aws_apigatewayv2_route.ws_messenger_api_sendprivate_route.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [ aws_apigatewayv2_integration.ws_messenger_api_integration]
}

resource "aws_apigatewayv2_stage" "ws_messenger_stage" {
  deployment_id = aws_apigatewayv2_deployment.ws_messenger_deployment.id
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  name    = "production"
  depends_on = [
    aws_apigatewayv2_deployment.ws_messenger_deployment
  ]
}

resource "aws_lambda_permission" "ws_messenger_lambda_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws_messenger_api_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_authorizer" "websocket-authorizer" {
  api_id           = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = var.lambda_invoke_arn
  identity_sources = ["route.request.header.Auth"]
  name             = "websocket-authorizer"
}

