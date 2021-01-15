{
 "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "SNSTopic": {
      "Type": "AWS::SNS::Topic",
      "Properties": {
        "TopicName": "${sns_topic_name}",
        "DisplayName": "${sns_display_name}",
        "Subscription": [
          ${sns_subscription_list}
        ],
        "Tags" : [
          {
          "Key" : "Name",
          "Value" : "${tag_topic_name}"
          }
        ]
      }
    }
  },
"Outputs" : {
   "SNSTopicArn" : {
      "Description" : "SNS Topic Arn",
      "Value" : {"Ref" : "SNSTopic"}
   }
}
}