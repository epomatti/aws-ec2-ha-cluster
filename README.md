# aws-ec2

to encrypt an instance, create the volume snapshot, clone it, encrypt it, and create an instance from the clone.



To create a AMI, select the instance and 'create image"


```sh
ssh -i id_rsa ec2-user@<ip_address>

sudo su - ec2-user
```

### Create an Encrypted Snapshot

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

### Create an Image from a Snapshot


```sh
aws ec2 register-image \
  --name "image-from-snapshot" \
  --region='sa-east-1' \
  --description "AMI_from_snapshot_EBS" \
  --block-device-mappings DeviceName="/dev/sda",Ebs={SnapshotId="snap-0123456789abcdef"} \
  --root-device-name "/dev/sda1"
```



```sh
aws ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "My server" \
  --description "An AMI for my server"
```