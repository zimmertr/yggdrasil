# The repo module on mock providers: what each kind of repo gets, and the one
# file a public repo can't have. Decision record 0043.

mock_provider "github" {}
mock_provider "restapi" {}

variables {
  owner = "zimmertr"
  name  = "example"
  settings = {
    description     = "An example"
    homepage_url    = null
    topics          = []
    visibility      = "public"
    archived        = false
    is_template     = false
    required_checks = ["PR Title / PR Title", "Lint / zizmor"]
  }
}

run "public_repo_gets_everything" {
  command = plan

  assert {
    condition = (
      github_repository.this.allow_squash_merge &&
      !github_repository.this.allow_merge_commit &&
      !github_repository.this.allow_rebase_merge &&
      github_repository.this.squash_merge_commit_title == "PR_TITLE" &&
      github_repository.this.squash_merge_commit_message == "PR_BODY"
    )
    error_message = "Squash only, titled and described by the PR."
  }

  assert {
    condition     = github_repository.this.archive_on_destroy
    error_message = "Removing a repo's file must archive it, not delete it."
  }

  assert {
    condition = (
      github_repository.this.security_and_analysis[0].secret_scanning[0].status == "enabled" &&
      github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    )
    error_message = "Secret scanning and push protection are on."
  }

  assert {
    condition = (
      length(github_repository_ruleset.default_branch) == 1 &&
      length(github_repository_ruleset.release_tags) == 1 &&
      length(restapi_object.private_vulnerability_reporting) == 1 &&
      length(restapi_object.codeql_default_setup) == 1 &&
      length(restapi_object.immutable_releases) == 1 &&
      length(github_repository_vulnerability_alerts.this) == 1 &&
      length(github_repository_dependabot_security_updates.this) == 1 &&
      github_actions_repository_permissions.this[0].sha_pinning_required
    )
    error_message = "A public repo gets every security setting."
  }

  assert {
    condition = (
      toset([for c in github_repository_ruleset.default_branch[0].rules[0].required_status_checks[0].required_check : c.context]) == toset(["PR Title / PR Title", "Lint / zizmor"]) &&
      alltrue([for c in github_repository_ruleset.default_branch[0].rules[0].required_status_checks[0].required_check : c.integration_id == 15368])
    )
    error_message = "Each required check is pinned to GitHub Actions."
  }

  assert {
    condition = (
      github_repository_ruleset.default_branch[0].rules[0].pull_request[0].required_approving_review_count == 0 &&
      github_repository_ruleset.default_branch[0].rules[0].pull_request[0].dismiss_stale_reviews_on_push &&
      github_repository_ruleset.default_branch[0].rules[0].pull_request[0].required_review_thread_resolution &&
      github_repository_ruleset.default_branch[0].rules[0].deletion &&
      github_repository_ruleset.default_branch[0].rules[0].non_fast_forward &&
      length(github_repository_ruleset.default_branch[0].bypass_actors) == 0
    )
    error_message = "main takes PRs only, with no bypass."
  }

  assert {
    condition     = length(github_repository_file.community) == 0
    error_message = "Terraform writes files only into a .github repo."
  }
}

run "github_repo_gets_the_shared_files" {
  command = plan

  variables {
    name = ".github"
    settings = {
      description     = ""
      homepage_url    = null
      topics          = []
      visibility      = "public"
      archived        = false
      is_template     = false
      required_checks = []
    }
  }

  assert {
    condition = toset(keys(github_repository_file.community)) == toset([
      ".github/ISSUE_TEMPLATE/bug.md",
      ".github/ISSUE_TEMPLATE/config.yml",
      ".github/ISSUE_TEMPLATE/proposal.md",
      "SECURITY.md",
    ])
    error_message = "Each file in community-health-files/ is written, the templates under .github/."
  }

  assert {
    condition = (
      github_repository_file.community["SECURITY.md"].content == file("../../../community-health-files/SECURITY.md") &&
      github_repository_file.community["SECURITY.md"].branch == "main"
    )
    error_message = "The copy on main matches yggdrasil's."
  }

  assert {
    condition = (
      length(github_repository_ruleset.default_branch[0].bypass_actors) == 1 &&
      github_repository_ruleset.default_branch[0].bypass_actors[0].actor_id == 5636772 &&
      github_repository_ruleset.default_branch[0].bypass_actors[0].actor_type == "Integration" &&
      length(github_repository_ruleset.default_branch[0].rules[0].pull_request) == 1
    )
    error_message = "Only the bot skips the PR rule, and everyone else still needs a PR."
  }

  assert {
    condition = (
      length(github_repository_ruleset.default_branch[0].rules[0].required_status_checks) == 0 &&
      length(restapi_object.codeql_default_setup) == 0 &&
      length(restapi_object.private_vulnerability_reporting) == 1
    )
    error_message = "A .github repo has no checks to require and no code for CodeQL, and keeps the rest."
  }
}

run "private_repo_skips_what_github_free_cannot_do" {
  command = plan

  variables {
    settings = {
      description     = ""
      homepage_url    = null
      topics          = []
      visibility      = "private"
      archived        = false
      is_template     = false
      required_checks = []
    }
  }

  assert {
    condition = (
      length(github_repository_ruleset.default_branch) == 0 &&
      length(github_repository_ruleset.release_tags) == 0 &&
      length(restapi_object.private_vulnerability_reporting) == 0 &&
      length(restapi_object.codeql_default_setup) == 0 &&
      length(github_repository.this.security_and_analysis) == 0
    )
    error_message = "A private repo gets no rulesets, CodeQL, private reporting or secret scanning on GitHub Free."
  }

  assert {
    condition = (
      length(restapi_object.immutable_releases) == 1 &&
      length(github_repository_vulnerability_alerts.this) == 1 &&
      length(github_repository_dependabot_security_updates.this) == 1 &&
      length(github_actions_repository_permissions.this) == 1
    )
    error_message = "A private repo still gets immutable releases, Dependabot and SHA pinning."
  }
}

run "archived_repo_keeps_only_the_repo" {
  command = plan

  variables {
    settings = {
      description     = ""
      homepage_url    = null
      topics          = []
      visibility      = "public"
      archived        = true
      is_template     = false
      required_checks = []
    }
  }

  assert {
    condition = (
      github_repository.this.archived &&
      length(github_repository_ruleset.default_branch) == 0 &&
      length(github_repository_ruleset.release_tags) == 0 &&
      length(restapi_object.immutable_releases) == 0 &&
      length(github_repository_vulnerability_alerts.this) == 0 &&
      length(github_actions_repository_permissions.this) == 0
    )
    error_message = "An archived repo is read-only, so only the repo stays managed."
  }
}

run "public_repo_without_required_checks_fails" {
  command = plan

  variables {
    settings = {
      description     = ""
      homepage_url    = null
      topics          = []
      visibility      = "public"
      archived        = false
      is_template     = false
      required_checks = []
    }
  }

  expect_failures = [github_repository.this]
}
