#!/bin/bash
set -euox pipefail

#Variables
ROLE_NAME=test-config
POLICY_NAME=my-policys
S3_BUCKET=prince-hellogds
SNS_TOPIC=test-topics

TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}'

CONFIG_CUSTOM_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*",
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::*",
        "arn:aws:sns:::*"
      ]
    }
  ]
}'


# Create Role
create_iam_role() {
role_create=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY")
ARN=`echo "$role_create" | grep -Po '"Arn":.*?".*?"' | awk '{ print $2 }' | sed -e 's/^"//' -e 's/"$//'`
echo "IAM ROLE ARN: $ARN"
}

# Attach AWS config Policy
attach_config_policy() {
policy_attach=$(aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSConfigRole)
}

# Create Custom Policy
create_custom_config_policy() {
policy_attach=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$CONFIG_CUSTOM_POLICY")
}
# Attach custom Policy to Config service
attach_custom_config_policy() {
policy_attach=$(aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::327557370220:policy/${POLICY_NAME})
}



# Create Bucket
create_s3_bucket() {
aws s3 mb s3://"${S3_BUCKET}"
}

# Create SNS
create_sns_topic() {
topic_arn=$(aws sns create-topic --name $SNS_TOPIC --output text)
echo "Topic ARN: $topic_arn"
}

#email=example@gmail.com

#subscription_arn=$(aws sns subscribe  --topic-arn "$topic_arn" --protocol email  --notification-endpoint "$email" --output text)


#Enabling AWS config
enable_aws_config() {
aws configservice subscribe --s3-bucket ${S3_BUCKET} --sns-topic $topic_arn --iam-role $ARN
}

create_iam_role
attach_config_policy
create_custom_config_policy
attach_custom_config_policy
create_sns_topic
create_s3_bucket
sleep 5s
enable_aws_config
