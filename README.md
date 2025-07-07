## 前提
リージョンは`us-east-1`

## 事前準備
- ComfyUIバックアップ用S3バケット作成  
`comfyui-backup-{アカウントID}`
- CIVITAIのAPIキーのSSMパラメータ作成  
`/comfy-ui/civitai-api-key`

## 初回
```bash
$ cdk bootstrap
```

## 通常フロー
```bash
$ cdk deploy
$ ssh -i ~/.ssh/comfy-ui.pem ubuntu@{パブリックIP}
```
以下インスタンス内
```bash
$ ./setup.sh
$ cd ComfyUI
$ python main.py --listen
```
`http:{パブリックIP}:8188`にアクセス

## modelダウンロード
```bash
# 例）
$ wget -c {ダウンロードURL} -P ./models/checkpoints/
```

## バックアップ
```bash
$ ./backup.sh
```

## 削除
```bash
$ cdk destroy
```
