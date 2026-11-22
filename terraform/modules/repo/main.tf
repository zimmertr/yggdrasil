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

  # An owner's .github repo holds the shared community health files, which
  # GitHub shows on every repo of that owner without its own (record 0041). It
  # has no code and no CI, and the bot commits the files to it (decision
  # record 0046).
  community = local.public && var.name == ".github"

  # zimmertr-yggdrasil-bot's App ID, public like its client ID.
  bot = 5636772

  # community-health-files/ISSUE_TEMPLATE/ goes to .github/ISSUE_TEMPLATE/,
  # and SECURITY.md, CONTRIBUTING.md and the README to the root.
  source_dir = "${path.module}/../../../community-health-files"
  community_files = local.community ? {
    for f in fileset(local.source_dir, "**") :
    (startswith(f, "ISSUE_TEMPLATE/") ? ".github/${f}" : f) => "${local.source_dir}/${f}"
  } : {}

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

  # A new repo starts from the template, so its first PR already runs the
  # checks its ruleset requires (decision record 0024). A .github repo has no
  # CI, so it starts empty.
  dynamic "template" {
    for_each = var.name == ".github" ? [] : [1]
    content {
      owner      = "zimmertr"
      repository = "yggdrasil-repo-template"
    }
  }

  # Squash only, titled and described by the PR (repo.md 9).
  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # repo.md 10.
  # GitHub Free has no auto-merge on a private repo, and doesn't save it.
  allow_auto_merge       = var.settings.visibility == "public"
  delete_branch_on_merge = true
  allow_update_branch    = true
  has_issues             = true
  has_wiki               = false
  has_projects           = false

  # Set, because the provider leaves it unset otherwise and an imported repo's
  # plan then shows Discussions being removed. Bluebird uses them.
  has_discussions = var.settings.has_discussions

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
    # Merge commits are off, and GitHub then ignores changes to these two, so
    # a repo imported with other values would show the same change on every
    # plan (docs/DATA.md).
    #
    # The template only matters when GitHub creates the repo. Changing it
    # would replace the repo, and an imported repo has none.
    ignore_changes = [merge_commit_title, merge_commit_message, template]

    # Removing every required check would leave main open to any PR. A .github
    # repo has no CI, so it has none to require.
    precondition {
      condition     = !local.public || local.community || length(var.settings.required_checks) > 0
      error_message = "${var.owner}/${var.name} is public, so it needs at least one required_checks entry."
    }
  }
}

# A PR for every change, 0 approvals, stale reviews dismissed, conversations
# resolved, the required checks, no force-push or deletion (security.md 1 to
# 4). No bypass actors, so admins are held too, except on a .github repo,
# where the bot commits the shared files straight to main (TJ, 2026-11-07).
resource "github_repository_ruleset" "default_branch" {
  count = local.public ? 1 : 0

  name        = "default branch"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  dynamic "bypass_actors" {
    for_each = local.community ? [local.bot] : []
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

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

    dynamic "required_status_checks" {
      for_each = length(var.settings.required_checks) > 0 ? [1] : []
      content {
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
# A .github repo holds no code to scan (TJ, 2026-11-07).
resource "restapi_object" "codeql_default_setup" {
  count = local.public && !local.community ? 1 : 0

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

# The shared community health files, copied from yggdrasil into a .github repo
# and committed by the bot (record 0046). This is the only file Terraform
# writes into any repo (record 0041).
resource "github_repository_file" "community" {
  for_each = local.community_files

  # No branch: the provider then writes to the default branch. With one set,
  # it first checks the branch exists, and a new, empty repo has none until
  # its first commit (docs/DATA.md).
  repository          = github_repository.this.name
  file                = each.key
  content             = file(each.value)
  commit_message      = "chore: update ${each.key} from zimmertr/yggdrasil"
  overwrite_on_create = true
}
