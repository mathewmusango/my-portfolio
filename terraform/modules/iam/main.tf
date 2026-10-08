resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_policy" "this" {
  for_each = var.inline_policies

  name   = each.value.name
  policy = each.value.policy
  tags   = var.tags

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "inline" {
  for_each = var.inline_policies

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}
