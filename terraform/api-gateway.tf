# ─────────────────────────────────────────────────────────────────────────────
# API Gateway (HTTP API) – proxy /api/* requests to backend EC2
# Used by CloudFront ordered behavior for /api/*
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "backend" {
  provider      = aws.no_tags
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "backend_proxy" {
  provider               = aws.no_tags
  api_id                 = aws_apigatewayv2_api.backend.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${aws_instance.backend.public_dns}:8080"
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "backend_api_root" {
  provider  = aws.no_tags
  api_id    = aws_apigatewayv2_api.backend.id
  route_key = "ANY /api"
  target    = "integrations/${aws_apigatewayv2_integration.backend_proxy.id}"
}

resource "aws_apigatewayv2_route" "backend_api_proxy" {
  provider  = aws.no_tags
  api_id    = aws_apigatewayv2_api.backend.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_proxy.id}"
}

resource "aws_apigatewayv2_stage" "backend_default" {
  provider    = aws.no_tags
  api_id      = aws_apigatewayv2_api.backend.id
  name        = "$default"
  auto_deploy = true
}
