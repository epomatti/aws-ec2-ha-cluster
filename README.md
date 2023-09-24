# AWS EC2 HA Cluster

High-availability EC2 cluster provisioned with Terraform.

<img src=".diagrams/aws.drawio.png" />

## 1 - Create the base instance & infrastructure

Start by creating a temporary key pair:

```sh
ssh-keygen -f ./tmp_rsa
```

Create the base infrastructure:

```sh
terraform -chdir="ami" init
terraform -chdir="ami" apply -auto-approve
```

The Apache instance should be available on port 80.


## 2 - Create the AMI

This instance is not encrypted, so create an encrypted snapshot:

```sh
# List the volumes
aws ec2 describe-volumes

# Create a snapshot
aws ec2 create-snapshot --volume-id 'vol-0123456789abcdef' --description 'Unencrypted' --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=Unencrypted}]'

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
  --name "ec2ha-encrypted" \
  --region='sa-east-1' \
  --description "AMI_from_snapshot_EBS" \
  --block-device-mappings DeviceName="/dev/sda",Ebs={SnapshotId="snap-0123456789abcdef"} \
  --root-device-name "/dev/sda1"
```

The image should now be available to be used for new launches.

Optionally, creating an image directly from a running instance is possible:

```sh
aws ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "My server" \
  --description "An AMI for my server"
```

Copy the AMI ID to use when creating the cluster.

## 3 - Create the HA cluster

CD into the `cluster` directory.

Create a `.auto.tfvars` file that points to the AMI:

```hcl
ami_id = "ami-0123456789abcdef"
```

Create the EC2 cluster:

```sh
terraform init
terraform apply -auto-approve
```

You should now be able to access the Apache server using the balancer URL:

```
http://ec2ha-lb-0123456789.sa-east-1.elb.amazonaws.com
```
