#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME=comfyui-backup-${AWS_ACCOUNT_ID}
CIVITAI_API_KEY=$(aws ssm get-parameter --name /comfy-ui/civitai-api-key --with-decryption --query Parameter.Value --output text --region us-east-1)


# ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ~/ComfyUI


# ComfyUI-Manager
git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/comfyui-manager


# requirements.txtをインストール
pip install -r requirements.txt


# S3から復元
aws s3 cp s3://$BUCKET_NAME/user/default/workflows ./user/default/workflows --recursive
aws s3 cp s3://$BUCKET_NAME/custom_nodes ./custom_nodes --recursive
aws s3 cp s3://$BUCKET_NAME/input ./input --recursive
aws s3 cp s3://$BUCKET_NAME/output ./output --recursive


# modelをダウンロード

## checkpoint
# wget -c "https://civitai.com/api/download/models/44398?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=${CIVITAI_API_KEY}" -O ./models/checkpoints/CityEdgeMix.safetensors
# wget -c https://huggingface.co/AIGaming/beautiful_realistic_asians/resolve/801a9b1999dd7018e58a1e2b432fdccd3d1d723d/beautifulRealistic_v7.safetensors -P ./models/checkpoints/

## vae
# wget -c https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors -P ./models/vae/

## Flux
wget -c https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev.safetensors -P ./models/diffusion_models/
wget -c https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors -P ./models/text_encoders/
wget -c https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors -P ./models/text_encoders/
wget -c https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors -P ./models/vae/
