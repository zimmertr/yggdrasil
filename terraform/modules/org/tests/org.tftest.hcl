# The org module on a mock provider: the profile comes from the file, and every
# org gets the same security defaults. Decision record 0051.

mock_provider "github" {}

variables {
  settings = {
    billing_email    = "tj@tjzimmerman.com"
    name             = "Example"
    description      = null
    blog             = null
    email            = null
    location         = null
    company          = null
    twitter_username = null
  }
}

run "takes_the_profile_from_the_file" {
  command = plan

  assert {
    condition = (
      github_organization_settings.this.name == "Example" &&
      github_organization_settings.this.billing_email == "tj@tjzimmerman.com"
    )
    error_message = "The name and billing email come from the org's file."
  }
}

run "new_repos_start_secure" {
  command = plan

  assert {
    condition = (
      github_organization_settings.this.dependency_graph_enabled_for_new_repositories &&
      github_organization_settings.this.dependabot_alerts_enabled_for_new_repositories &&
      github_organization_settings.this.dependabot_security_updates_enabled_for_new_repositories &&
      github_organization_settings.this.secret_scanning_enabled_for_new_repositories &&
      github_organization_settings.this.secret_scanning_push_protection_enabled_for_new_repositories &&
      !github_organization_settings.this.advanced_security_enabled_for_new_repositories
    )
    error_message = "A new repo gets the repo module's security settings before its import; Advanced Security stays off on GitHub Free."
  }

  assert {
    condition     = github_organization_settings.this.has_repository_projects
    error_message = "Repo projects stay on at the org, so the repo module can turn them off per repo."
  }
}
