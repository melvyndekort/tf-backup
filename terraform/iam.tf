data "aws_iam_policy_document" "lmbackup" {
  statement {
    actions = [
      "s3:List*",
      "s3:Get*",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.backup.id}",
      "arn:aws:s3:::${aws_s3_bucket.portainer.id}",
    ]
  }
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.backup.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.portainer.id}/*",
    ]
  }
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      data.terraform_remote_state.tf_aws.outputs.generic_kms_key_arn,
    ]
  }
}

resource "aws_iam_user_policy" "lmbackup" {
  user   = data.terraform_remote_state.tf_aws.outputs.lmbackup_name
  policy = data.aws_iam_policy_document.lmbackup.json
}
