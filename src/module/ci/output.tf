output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "github_actions_policy_arn" {
  value = aws_iam_policy.github_actions.arn
}

output "github_actions_role_name" {
  value = aws_iam_role.github_actions.name
}

output "github_actions_policy_name" {
  value = aws_iam_policy.github_actions.name
}