#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME=comfyui-backup-${AWS_ACCOUNT_ID}


cd ~/ComfyUI


# zip化してS3にバックアップ
zip -r ./backup.zip ./user/default/workflows ./custom_nodes \
  -x "custom_nodes/comfyui-manager/**" \
  -x "custom_nodes/comfyui-manager"
aws s3 cp ./backup.zip s3://$BUCKET_NAME/backup.zip
rm ./backup.zip
