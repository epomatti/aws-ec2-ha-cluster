# AWS EC2 HA Cluster

A high-availability EC2 instances cluster.

## 1 - Create the base instance & infrastructure

Enter the AMI directory and create the base infrastructure.

```sh
cd ami

terraform init
terraform apply -auto-approve
```

An Apache instance should be available on port 80.

To confirm everything is working:

```sh
ssh -i id_rsa ec2-user@<ip_address>

sudo su - ec2-user
```

## 2 - Create the AMI

This instance is not encrypted, so create an encrypted snapshot:

```sh
# List the volumes
aws ec2 describe-volumes

# Create a snapshot
aws ec2 create-snapshot --volume-id 'vol-0123456789abcdef' --description 'Unencrypted' --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=test}]'

# Make an encrypted copy of a snapshot
aws ec2 copy-snapshot \
  --source-region 'sa-east-1' \
  --source-snapshot-id 'snap-0123456789abcdef' \
  --description 'Encrypted' \
  --encrypted
```

Now create the image from the snapshot:

```sh
aws ec2 register-image \
  --name "image-from-snapshot" \
  --region='sa-east-1' \
  --description "AMI_from_snapshot_EBS" \
  --block-device-mappings DeviceName="/dev/sda",Ebs={SnapshotId="snap-0123456789abcdef"} \
  --root-device-name "/dev/sda1"
```

Optionally, create an Image directly from a running instance is possible:

```sh
aws ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "My server" \
  --description "An AMI for my server"
```

### 3 - 