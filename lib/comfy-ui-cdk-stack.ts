import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { readFileSync } from 'fs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';

export class ComfyUiCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);


    // デフォルトVPCを取得
    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVpc', {
      isDefault: true,
    });


    // Security Group（ssh22とhttp8188）
    const securityGroup = new ec2.SecurityGroup(this, 'ComfyUiSecurityGroup', {
      securityGroupName: 'comfy-ui',
      vpc,
      description: 'Security group for ComfyUi',
      allowAllOutbound: true,
    });
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'Allow SSH traffic');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(8188), 'Allow HTTP traffic');


    // S3バケット（ComfyUIのバックアップ用）
    const comfyUiBackupBucket = s3.Bucket.fromBucketName(
      this,
      'ComfyUiBackupBucket',
      `comfyui-backup-${this.account}`,
    );


    // EC2 Instance
    const userData = ec2.UserData.forLinux();
    const setupScript = readFileSync('./lib/setup.sh', 'utf8');
    userData.addCommands(
      `cat << 'EOF' > /home/ubuntu/setup.sh`,
      `${setupScript}`,
      `EOF`,
      `chmod +x /home/ubuntu/setup.sh`,
      `chown ubuntu:ubuntu /home/ubuntu/setup.sh`,
    );
    const backupScript = readFileSync('./lib/backup.sh', 'utf8');
    userData.addCommands(
      `cat << 'EOF' > /home/ubuntu/backup.sh`,
      `${backupScript}`,
      `EOF`,
      `chmod +x /home/ubuntu/backup.sh`,
    );
    
    // civitiapikeyアクセスのためのロール
    const instanceRole = new iam.Role(this, 'InstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
    });
    instanceRole.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMReadOnlyAccess'));
    instanceRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        's3:GetObject',
        's3:PutObject',
        's3:ListBucket',
      ],
      resources: [
        comfyUiBackupBucket.bucketArn,
        comfyUiBackupBucket.bucketArn + '/*',
      ],
    }));

    const instance = new ec2.Instance(this, 'ComfyUiInstance', {
      instanceName: 'comfy-ui',
      vpc,
      availabilityZone: 'us-east-1d',
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.G4DN, ec2.InstanceSize.XLARGE), // 安価（GPUメモリ16GB）
      // instanceType: ec2.InstanceType.of(ec2.InstanceClass.G6, ec2.InstanceSize.XLARGE2), // Flux使うならこれ（GPUメモリ32GB）
      machineImage: ec2.MachineImage.genericLinux({
        // Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.7 (Ubuntu 22.04)
        'us-east-1': 'ami-05ee60afff9d0a480',
      }),
      keyPair: ec2.KeyPair.fromKeyPairName(this, 'ComfyUiKeyPair', 'comfy-ui'),
      securityGroup: securityGroup,
      role: instanceRole,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      blockDevices: [
        {
          deviceName: '/dev/sda1',
          volume: ec2.BlockDeviceVolume.ebs(100, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
            iops: 3000,
            encrypted: true,
            deleteOnTermination: true,
          }),
        },
      ],
      userData: userData,
    });

    const launchTemplate = new ec2.LaunchTemplate(this, 'ComfyUiLaunchTemplate', {
      spotOptions: {},
    });
    instance.instance.launchTemplate = {
      version: launchTemplate.versionNumber,
      launchTemplateId: launchTemplate.launchTemplateId,
    }


    // 出力
    new cdk.CfnOutput(this, 'PublicIp', {
      value: instance.instancePublicIp,
    });

    new cdk.CfnOutput(this, 'AccessURL', {
      value: `http://${instance.instancePublicIp}:8188`,
    });
  }
}
