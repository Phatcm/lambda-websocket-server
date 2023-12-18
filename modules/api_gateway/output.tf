output "api_gateway_invoke_url" {
  value = aws_apigatewayv2_stage.ws_messenger_stage.invoke_url
}