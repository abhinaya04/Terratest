variable "region" {
  default = "ap-southeast-1"
}

variable "access_key" {
}

variable "secret_key" {
}

variable "topic_name" {
  default = "s3-event-topic"
}
variable "tag_topic_name" {
  default = "sns-topic-name"
  
}
variable "bucket_name" {
  default = "s3-event-bucket-99978886"
}

variable "sns_subscription_email_address_list" {
  type    = list(string)
  default = ["abhinayatrash@gmail.com"] ### Add the email addresses to which alerts to be sent
}

variable "sns_subscription_protocol" {
  default = "email"
}

variable "tag_bucket_environment" {
  description = "The Environment tag to set for the S3 Bucket."
  type        = string
  default     = "Test"
}

variable "tag_bucket_name" {
  description = "The Name tag to set for the S3 Bucket."
  type        = string
  default     = "s3-event-bucket-99978886"
}

variable "with_policy" {
  description = "If set to `true`, the bucket will be created with a bucket policy."
  type        = bool
  default     = false
}

