# aws-ec2

to encrypt an instance, create the volume snapshot, clone it, encrypt it, and create an instance from the clone.


start EC2 pache

```sh
#!/usr/bin/env bash
su ec2-user
sudo yum install httpd -y
sudo service httpd start
sudo chkconfig httpd on
```


To create a AMI, select the instance and 'create image"
