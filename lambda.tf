resource "aws_lambda_function" "main" {
  filename      = data.archive_file.lambda.output_path
  function_name = "nkbot-chat"
  role          = aws_iam_role.lambda_kb.arn
  handler       = "chat.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
  timeout = 30

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.kb.id
    }
  }

  logging_config {
    log_format = "Text"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
  ]
}


data "archive_file" "lambda" {
  type        = "zip"
  source_file = "backend/chat.py"
  output_path = "backend/chat.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/nkbot-chat"
  retention_in_days = 30
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "lambda_basic_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "invoke" {
  name        = "bedrock_claude_access"
  path        = "/"
  description = "Bedrock Claude Model Access Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["bedrock:InvokeModel"]
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.claude.model_arn
      },
    ]
  })
}

resource "aws_iam_policy" "kb" {
  name        = "bedrock_kb_access"
  path        = "/"
  description = "Bedrock Knowledge Base Access Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["bedrock:Retrieve", "bedrock:RetrieveAndGenerate"]
        Effect   = "Allow"
        Resource = aws_bedrockagent_knowledge_base.kb.arn
      },
    ]
  })
}

resource "aws_iam_role" "lambda_kb" {
  name                = "RagRoleForLambda"
  assume_role_policy  = data.aws_iam_policy_document.lambda.json
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution.arn, aws_iam_policy.invoke.arn, aws_iam_policy.kb.arn]
}

resource "aws_lambda_permission" "api" {
  statement_id  = "allowInvokeFromAPIGatewayRoute"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:${local.partition}:execute-api:ap-northeast-2:${local.account_id}:${aws_apigatewayv2_api.main.id}/*"
}