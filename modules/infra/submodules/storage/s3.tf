locals {
  s3_server_side_encryption = var.kms_info.enabled ? "aws:kms" : "AES256"
}

resource "aws_s3_bucket" "backups" {
  bucket              = "${var.deploy_id}-backups"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false

  tags = local.backup_tagging
}

data "aws_iam_policy_document" "backups" {
  statement {
    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.backups.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.backups.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.backups.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.backups.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "blobs" {
  bucket              = "${var.deploy_id}-blobs"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false

  tags = local.backup_tagging
}

data "aws_iam_policy_document" "blobs" {
  statement {

    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.blobs.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.blobs.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }


  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.blobs.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.blobs.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket              = "${var.deploy_id}-logs"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false

  tags = local.backup_tagging
}

data "aws_iam_policy_document" "logs" {
  statement {

    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.logs.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.logs.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.logs.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.logs.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "monitoring" {
  bucket              = "${var.deploy_id}-monitoring"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false

}

data "aws_iam_policy_document" "monitoring" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "ELBLogDelivery"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}/*"]

    actions = [
      "s3:PutObject*",
      "s3:Abort*",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryCheck"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}"]

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
    ]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSAccessLogDeliveryWrite"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSAccessLogDeliveryAclCheck"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.monitoring.bucket}"]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "monitoring" {
  bucket = aws_s3_bucket.monitoring.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "terraform_data" "set_monitoring_private_acl" {
  provisioner "local-exec" {
    command     = <<-EOF
      set -x -o pipefail

      sleep_duration=10
      bucket="${aws_s3_bucket.monitoring.bucket}"

      update_bucket() {
        ownership=$(aws s3api get-bucket-ownership-controls --bucket $bucket --output text --query "OwnershipControls.Rules[0]")
        if [[ "$ownership" == "BucketOwnerPreferred" ]] || [[ -z "$ownership" ]]; then
          aws s3api put-bucket-acl --bucket $bucket --acl private || return 1
          aws s3api put-bucket-ownership-controls --bucket $bucket --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]" || return 1
        fi

        return 0
      }

      for _ in {1..3}; do
        if update_bucket; then
          exit 0
        fi

        sleep "$sleep_duration"
      done

      echo "Could not set bucket ownership for $bucket"
      exit 1
    EOF
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_s3_bucket.monitoring]
}

resource "aws_s3_bucket" "registry" {
  bucket              = "${var.deploy_id}-registry"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false
}

data "aws_iam_policy_document" "registry" {
  statement {
    effect = "Deny"
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.registry.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.registry.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.registry.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.registry.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "buckets_policies" {
  for_each = local.s3_buckets
  bucket   = each.value.id
  policy   = each.value.policy_json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets_encryption" {
  for_each = { for k, v in local.s3_buckets : k => v if k != "monitoring" }

  bucket = each.value.bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.s3_server_side_encryption
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = false
  }

  lifecycle {
    ignore_changes = [
      rule,
    ]
  }
}

resource "aws_s3_bucket_request_payment_configuration" "buckets_payer" {
  for_each = local.s3_buckets
  bucket   = each.value.bucket_name
  payer    = "BucketOwner"
}

resource "aws_s3_bucket_logging" "buckets_logging" {
  for_each      = { for k, v in local.s3_buckets : k => v if k != "monitoring" }
  bucket        = each.value.id
  target_bucket = aws_s3_bucket.monitoring.bucket
  target_prefix = "${each.value.bucket_name}/"
}

resource "aws_s3_bucket_versioning" "buckets_versioning" {
  for_each = local.s3_buckets
  bucket   = each.value.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  for_each                = local.s3_buckets
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


moved {
  from = aws_s3_bucket_public_access_block.block_public_accss
  to   = aws_s3_bucket_public_access_block.block_public_access
}

resource "aws_s3_bucket" "costs" {
  count               = var.storage.costs_enabled ? 1 : 0
  bucket              = "${var.deploy_id}-costs"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false
}

resource "aws_s3_bucket_lifecycle_configuration" "costs" {
  count  = var.storage.costs_enabled ? 1 : 0
  bucket = aws_s3_bucket.costs[0].id

  rule {
    id = "AssetsExpiration"

    expiration {
      days = 15
    }

    filter {
      prefix = "federated/${var.deploy_id}/etl/bingen/assets/"
    }

    status = "Enabled"
  }


  rule {
    id = "AllocationsExpiration"

    expiration {
      days = 15
    }

    filter {
      prefix = "federated/${var.deploy_id}/etl/bingen/allocations/"
    }

    status = "Enabled"
  }

  rule {
    id = "incomplete_upload"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    status = "Enabled"
  }

  depends_on = [
    aws_s3_bucket.costs
  ]
}

data "aws_iam_policy_document" "costs" {
  count = var.storage.costs_enabled ? 1 : 0

  statement {
    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs[0].bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs[0].bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs[0].bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs[0].bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
