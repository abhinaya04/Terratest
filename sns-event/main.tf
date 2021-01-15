provider "aws" {
  region     = "ap-southeast-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Fetching current account id
data "aws_caller_identity" "current" {}

# Creating S3 Bucket
resource "aws_s3_bucket" "s3-event-bucket" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }
  logging {
    target_bucket = aws_s3_bucket.bucket_event_logs.id
    target_prefix = "/"
  }
  tags = {
    Name        = var.tag_bucket_name
    Environment = var.tag_bucket_environment
  }
  force_destroy = true
}

resource "aws_s3_bucket" "bucket_event_logs" {
  bucket = "${var.bucket_name}-logs"
  acl    = "log-delivery-write"

  tags = {
    Name        = "${data.aws_caller_identity.current.account_id}-logs"
    Environment = var.tag_bucket_environment
  }

  force_destroy = true
}

resource "aws_s3_bucket_policy" "bucket_access_policy" {
  count  = var.with_policy ? 1 : 0
  bucket = aws_s3_bucket.s3-event-bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
  depends_on = [aws_s3_bucket.s3-event-bucket]
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [data.aws_caller_identity.current.account_id]
      type        = "AWS"
    }
    actions   = ["*"]
    resources = ["${aws_s3_bucket.s3-event-bucket.arn}/*"]
  }

  statement {
    effect = "Deny"
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    actions   = ["*"]
    resources = ["${aws_s3_bucket.s3-event-bucket.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }
  }
}
# Creating a CFN Stack for provisioning SNS Topic
data "template_file" "aws_cf_sns_stack" {
  template = file("${path.module}/cf_aws_sns_email_stack.json.tpl")
  vars = {
    sns_topic_name   = var.topic_name
    sns_display_name = var.topic_name
    tag_topic_name = var.tag_topic_name
    sns_subscription_list = join(",", formatlist("{\"Endpoint\": \"%s\",\"Protocol\": \"%s\"}",
      var.sns_subscription_email_address_list,
    var.sns_subscription_protocol))
  }
}

resource "aws_cloudformation_stack" "sns_topic" {
  name          = "SNSStack"
  template_body = data.template_file.aws_cf_sns_stack.rendered
  tags = {
    name = "SNS-Stack"
  }
}

# Creating S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3-event-bucket.id
  topic {
    topic_arn = aws_cloudformation_stack.sns_topic.outputs["SNSTopicArn"]
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_s3_bucket_policy.bucket_access_policy]
}

# Creating SNS Topic Policy
resource "aws_sns_topic_policy" "default" {
  arn    = aws_cloudformation_stack.sns_topic.outputs["SNSTopicArn"]
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = ["SNS:Publish"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.s3-event-bucket.arn,
      ]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${aws_cloudformation_stack.sns_topic.outputs["SNSTopicArn"]}",
    ]
  }
}

output "bucket_id" {
  value = aws_s3_bucket.s3-event-bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.s3-event-bucket.arn
}
output "sns_topic_arn" {
  value = "${aws_cloudformation_stack.sns_topic.outputs["SNSTopicArn"]}"
}

# output "logging_target_bucket" {
#   value = tolist(aws_s3_bucket.test_bucket.logging)[0].target_bucket
# }