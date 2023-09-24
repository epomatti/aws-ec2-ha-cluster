### Key to encrypt the AMI ###
resource "aws_kms_key" "ami" {
  description             = "Temporary key to test AMI encryption permissions when launching EC2 instances"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "a" {
  name          = "alias/ami-kms"
  target_key_id = aws_kms_key.ami.key_id
}


### User able to launch EC2, but not KMS ###
resource "aws_iam_user" "ec2" {
  name          = "ec2launcher"
  path          = "/security/"
  force_destroy = true
}

data "aws_iam_policy_document" "ec2" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "ec2" {
  name   = "temp-policyToLaunchEC2"
  user   = aws_iam_user.ec2.name
  policy = data.aws_iam_policy_document.ec2.json
}
