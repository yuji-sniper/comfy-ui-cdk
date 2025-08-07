#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
BUCKET_NAME=comfyui-backup-${AWS_ACCOUNT_ID}-${AWS_REGION}
CIVITAI_API_KEY=$(aws ssm get-parameter --name /comfy-ui/civitai-api-key --with-decryption --query Parameter.Value --output text --region ${AWS_REGION})


# zip, unzipをインストール
sudo apt update
sudo apt install -y zip unzip


# ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ~/ComfyUI


# カスタムノードをgit clone
git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/comfyui-manager
# git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git custom_nodes/comfyui-impact-pack
# git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git custom_nodes/comfyui-impact-subpack
# git clone https://github.com/kijai/ComfyUI-KJNodes.git custom_nodes/comfyui-kjnodes


# バックアップを復元
aws s3 cp s3://$BUCKET_NAME/backup.zip .
unzip -o ./backup.zip


# requirements.txtをインストール
pip install -r requirements.txt


# modelをダウンロード

## checkpoint
wget -c "https://civitai.com/api/download/models/134361?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=${CIVITAI_API_KEY}" -O models/checkpoints/epiCRealism_inpainting.safetensors
wget -c "https://civitai.com/api/download/models/176425?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=${CIVITAI_API_KEY}" -O ./models/checkpoints/majicMIXrealistic.safetensors
wget -c "https://civitai.com/api/download/models/221343?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=${CIVITAI_API_KEY}" -O ./models/checkpoints/majicMIXrealistic_inpainting.safetensors
wget -c https://huggingface.co/AIGaming/beautiful_realistic_asians/resolve/801a9b1999dd7018e58a1e2b432fdccd3d1d723d/beautifulRealistic_v7.safetensors -P ./models/checkpoints/
# wget -c "https://civitai.com/api/download/models/44398?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=${CIVITAI_API_KEY}" -O ./models/checkpoints/CityEdgeMix.safetensors

## vae
wget -c https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors -P ./models/vae/

## Flux
# wget -c https://huggingface.co/Comfy-Org/flux1-kontext-dev_ComfyUI/resolve/main/split_files/diffusion_models/flux1-dev-kontext_fp8_scaled.safetensors -P ./models/diffusion_models/
# wget -c https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors -P ./models/text_encoders/
# wget -c https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors -P ./models/text_encoders/
# wget -c https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors -P ./models/vae/
