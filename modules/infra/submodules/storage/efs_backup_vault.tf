resource "aws_backup_vault" "efs" {
  count = var.storage.efs.backup_vault.create ? 1 : 0
  name  = "${var.deploy_id}-efs"

  force_destroy = var.storage.efs.backup_vault.force_destroy
  kms_key_arn   = local.kms_key_arn

  lifecycle {
    ignore_changes = [
      kms_key_arn,
    ]
  }


}

resource "aws_backup_plan" "efs" {
  count = var.storage.efs.backup_vault.create ? 1 : 0
  name  = "${var.deploy_id}-efs"
  rule {
    rule_name           = "efs-rule"
    recovery_point_tags = {}
    schedule            = "cron(${var.storage.efs.backup_vault.backup.schedule})"
    start_window        = 60
    target_vault_name   = aws_backup_vault.efs[0].name

    lifecycle {
      cold_storage_after = var.storage.efs.backup_vault.backup.cold_storage_after
      delete_after       = var.storage.efs.backup_vault.backup.delete_after
    }
  }
}

data "aws_iam_policy" "aws_backup_role_policy" {
  count = var.storage.efs.backup_vault.create ? 1 : 0
  name  = "AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role" "efs_backup_role" {
  count = var.storage.efs.backup_vault.create ? 1 : 0
  name  = "${var.deploy_id}-efs-backup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_backup_role_attach" {
  count      = var.storage.efs.backup_vault.create ? 1 : 0
  role       = aws_iam_role.efs_backup_role[0].name
  policy_arn = data.aws_iam_policy.aws_backup_role_policy[0].arn
}

resource "aws_backup_selection" "efs" {
  count = var.storage.efs.backup_vault.create ? 1 : 0
  name  = "${var.deploy_id}-efs"

  plan_id      = aws_backup_plan.efs[0].id
  iam_role_arn = aws_iam_role.efs_backup_role[0].arn

  resources = [aws_efs_file_system.eks.arn]
}
