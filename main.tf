# Define input variables
variable "email_address" {
  description = "The email address to send notifications to"
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function to monitor"
  type        = string
}

# Create an SNS topic
resource "aws_sns_topic" "lambda_alarm_topic" {
  name = "lambda_alarm_topic"
}

# Create an SNS topic subscription
resource "aws_sns_topic_subscription" "lambda_alarm_subscription" {
  topic_arn = aws_sns_topic.lambda_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# Create a CloudWatch log metric filter
resource "aws_cloudwatch_log_metric_filter" "lambda_metric_filter" {
  name           = "LambdaErrorMetricFilter"
  log_group_name = "/aws/lambda/${var.lambda_function_name}"
  pattern        = "{ $.errorMessage = \"*\" }"

  metric_transformation {
    name      = "LambdaErrorCount"
    namespace = "LambdaMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "lambda_alarm" {
  alarm_name          = "LambdaErrorAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.lambda_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.lambda_metric_filter.metric_transformation[0].namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  alarm_actions = [
    aws_sns_topic.lambda_alarm_topic.arn
  ]
}
