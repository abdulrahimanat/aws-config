#!/bin/bash
#set -euox pipefail
#set -x
#Variables
ROLE_NAME=test-confide
POLICY_NAME=my-polidw
S3_BUCKET=hellogdsffffdfhsfb
SNS_TOPIC=test-topicssdq
AWS_REGION=eu-central-1
includeGlobalResourceTypes=false #true or false whether or not Global services to be enabled or not


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
policy_attach=$(aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::211539041645:policy/${POLICY_NAME})
}


# Create Bucket
create_s3_bucket() {
aws s3 mb s3://"${S3_BUCKET}" --region $AWS_REGION
}

# Create SNS
create_sns_topic() {
topic_arn=$(aws sns create-topic --name $SNS_TOPIC --region $AWS_REGION --output text)
echo "Topic ARN: $topic_arn"
}

#email=example@gmail.com

#subscription_arn=$(aws sns subscribe  --topic-arn "$topic_arn" --protocol email  --notification-endpoint "$email" --output text)


#Enabling AWS config
#enable_aws_config() {
#aws configservice subscribe --s3-bucket ${S3_BUCKET} --sns-topic $topic_arn --iam-role $ARN
#}

put_config() {
put_config=$(aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=$ARN --recording-group allSupported=true,includeGlobalResourceTypes=$includeGlobalResourceTypes --region $AWS_REGION)
}

# SNS topic has to be create before it's ARN has called in delivery channel
create_sns_topic


cat <<EOF >./delivery.json
"name": "default",
"s3BucketName": "${S3_BUCKET}",
"snsTopicARN": "${topic_arn}",
"configSnapshotDeliveryProperties": {
"deliveryFrequency": "TwentyFour_Hours"
}
}
EOF

enable_aws_config() {
put_delivery=$(aws configservice put-delivery-channel --delivery-channel file://./delivery.json --region $AWS_REGION) 
enable_aws_config=$(aws configservice start-configuration-recorder --configuration-recorder-name default --region $AWS_REGION) 
}


create_iam_role
attach_config_policy
create_custom_config_policy
attach_custom_config_policy
create_s3_bucket
sleep 10s
put_config
enable_aws_config
