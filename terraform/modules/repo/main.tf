# One repo and every setting initialize-project gives a new one, mapped to its
# resource in docs/CONFIGURATION.md's "What Terraform manages". No security
# setting is an input: each is on wherever GitHub allows it (decision record
# 0043).

locals {
  # An archived repo is read-only: GitHub refuses changes to its settings, so
  # only the repo itself stays managed.
  active = !var.settings.archived

  # GitHub Free gives a private repo no rulesets, no CodeQL default setup and
  # no private vulnerability reporting (record 0039).
  public = local.active && var.settings.visibility == "public"

  # GitHub Actions' app id. A required check names the app that must report
  # it, so no other app can satisfy it by posting a status of the same name
  # (record 0024).
  github_actions = 15368

  path = "/repos/${var.owner}/${var.name}"
}

# Most of TJ's repos are public on purpose: they are the source. Trivy flags
# every public repo Critical (GIT-0001), checked 2026-11-06.
# trivy:ignore:GIT-0001
resource "github_repository" "this" {
  name         = var.name
  description  = var.settings.description
  homepage_url = var.settings.homepage_url
  topics       = var.settings.topics
  visibility   = var.settings.visibility
  archived     = var.settings.archived
  is_template  = var.settings.is_template

  # Removing a repo's file archives the repo, never deletes it (record 0035).
  archive_on_destroy = true

  # Squash only, titled and described by the PR (repo.md 9).
  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # repo.md 10.
  allow_auto_merge       = true
  delete_branch_on_merge = true
  allow_update_branch    = true
  has_issues             = true
  has_wiki               = false
  has_projects           = false

  # Secret scanning and push protection are free on public repos only.
  dynamic "security_and_analysis" {
    for_each = local.public ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  lifecycle {
    # Removing every required check would leave main open to any PR.
    precondition {
      condition     = !local.public || length(var.settings.required_checks) > 0
      error_message = "${var.owner}/${var.name} is public, so it needs at least one required_checks entry."
    }
  }
}

# A PR for every change, 0 approvals, stale reviews dismissed, conversations
# resolved, the required checks, no force-push or deletion (security.md 1 to
# 4). No bypass actors, so admins are held too.
resource "github_repository_ruleset" "default_branch" {
  count = local.public ? 1 : 0

  name        = "default branch"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      required_review_thread_resolution = true
      allowed_merge_methods             = ["squash"]
    }

    required_status_checks {
      strict_required_status_checks_policy = false

      dynamic "required_check" {
        for_each = var.settings.required_checks
        content {
          context        = required_check.value
          integration_id = local.github_actions
        }
      }
    }
  }
}

# A release tag can't be moved or deleted, so a caller's pinned `# vX.Y.Z`
# always means the same commit. Creating one stays open for the release
# workflow (TJ, 2026-11-05).
resource "github_repository_ruleset" "release_tags" {
  count = local.public ? 1 : 0

  name        = "release tags"
  repository  = github_repository.this.name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/tags/v*"]
      exclude = []
    }
  }

  rules {
    update   = true
    deletion = true
  }
}

# security.md 6.
resource "github_repository_vulnerability_alerts" "this" {
  count = local.active ? 1 : 0

  repository = github_repository.this.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "this" {
  count = local.active ? 1 : 0

  repository = github_repository.this.name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.this]
}

# Every action pinned to a full commit SHA.
resource "github_actions_repository_permissions" "this" {
  count = local.active ? 1 : 0

  repository           = github_repository.this.name
  enabled              = true
  allowed_actions      = "all"
  sha_pinning_required = true
}

# The three settings integrations/github has no resource for (record 0024).
# Each endpoint is one setting with no id of its own, so the object's id is
# fixed and every call goes to the same path. ignore_server_additions keeps
# the fields GitHub returns out of the plan.

# security.md 21.
resource "restapi_object" "private_vulnerability_reporting" {
  count = local.public ? 1 : 0

  path                    = "${local.path}/private-vulnerability-reporting"
  object_id               = "private-vulnerability-reporting"
  read_path               = "${local.path}/private-vulnerability-reporting"
  update_path             = "${local.path}/private-vulnerability-reporting"
  destroy_path            = "${local.path}/private-vulnerability-reporting"
  create_method           = "PUT"
  update_method           = "PUT"
  destroy_method          = "DELETE"
  data                    = jsonencode({})
  ignore_server_additions = true

  depends_on = [github_repository.this]
}

# security.md 18. The endpoint refuses a body with any key, so Terraform can't
# see it being turned off by hand (docs/DATA.md).
resource "restapi_object" "immutable_releases" {
  count = local.active ? 1 : 0

  path                    = "${local.path}/immutable-releases"
  object_id               = "immutable-releases"
  read_path               = "${local.path}/immutable-releases"
  update_path             = "${local.path}/immutable-releases"
  destroy_path            = "${local.path}/immutable-releases"
  create_method           = "PUT"
  update_method           = "PUT"
  destroy_method          = "DELETE"
  data                    = jsonencode({})
  ignore_server_additions = true

  depends_on = [github_repository.this]
}

# security.md 13. Only the state is set: GitHub picks the languages, and
# reports none until the first analysis ends, about a minute in (docs/DATA.md).
resource "restapi_object" "codeql_default_setup" {
  count = local.public ? 1 : 0

  path                    = "${local.path}/code-scanning/default-setup"
  object_id               = "code-scanning-default-setup"
  read_path               = "${local.path}/code-scanning/default-setup"
  update_path             = "${local.path}/code-scanning/default-setup"
  destroy_path            = "${local.path}/code-scanning/default-setup"
  create_method           = "PATCH"
  update_method           = "PATCH"
  destroy_method          = "PATCH"
  data                    = jsonencode({ state = "configured" })
  destroy_data            = jsonencode({ state = "not-configured" })
  ignore_server_additions = true

  depends_on = [github_repository.this]
}
