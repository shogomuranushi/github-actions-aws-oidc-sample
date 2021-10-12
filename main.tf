terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  # Please change here
  region = "ap-northeast-1"
}

locals {
  # Please change here
  github_oidc_domain = "token.actions.githubusercontent.com"
  # Please change here
  reponame = "abeja-inc/github-actions-aws-oidc-sample"
}

# IAM Role
resource "aws_iam_role" "github_actoins" {
  name               = "GitHubActions"
  description        = "GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.assume_github.json
}

resource "aws_iam_role_policy_attachment" "github_actions1" {
  role       = aws_iam_role.github_actoins.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "sts" {
  name   = "stspolicy"
  role   = aws_iam_role.github_actoins.name
  policy = data.aws_iam_policy_document.sts.json
}

data "aws_iam_policy_document" "sts" {
  statement {
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_github" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_domain}:sub"
      values   = ["repo:${local.reponame}:*"]
    }
  }
}

# IdP
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://${local.github_oidc_domain}"
  client_id_list  = ["sigstore"]
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
}
