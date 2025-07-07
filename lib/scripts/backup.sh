#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME=comfyui-backup-${AWS_ACCOUNT_ID}


cd ~/ComfyUI


# バックアップ
aws s3 cp ./user/default/workflows s3://$BUCKET_NAME/user/default/workflows --recursive --storage-class INTELLIGENT_TIERING
aws s3 cp ./custom_nodes s3://$BUCKET_NAME/custom_nodes --recursive --storage-class INTELLIGENT_TIERING
aws s3 cp ./input s3://$BUCKET_NAME/input --recursive --storage-class INTELLIGENT_TIERING
aws s3 cp ./output s3://$BUCKET_NAME/output --recursive --storage-class INTELLIGENT_TIERING
