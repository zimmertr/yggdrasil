# One org's settings. The provider passed in is that org's, so the resource
# needs no org name. Decision record 0051.

resource "github_organization_settings" "this" {
  billing_email    = var.settings.billing_email
  name             = var.settings.name
  description      = var.settings.description
  blog             = var.settings.blog
  email            = var.settings.email
  location         = var.settings.location
  company          = var.settings.company
  twitter_username = var.settings.twitter_username

  # A repo made by hand, before its import, starts with the security settings
  # the repo module would give it. Advanced Security isn't on GitHub Free.
  dependency_graph_enabled_for_new_repositories                = true
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
  advanced_security_enabled_for_new_repositories               = false

  # GitHub's defaults, set so a hand change shows in the plan. Each org has
  # one member, its owner, whom these don't limit.
  default_repository_permission           = "read"
  members_can_create_repositories         = true
  members_can_create_public_repositories  = true
  members_can_create_private_repositories = true
  members_can_create_pages                = true
  members_can_create_public_pages         = true
  members_can_create_private_pages        = true
  members_can_fork_private_repositories   = false
  web_commit_signoff_required             = false

  # Repo projects stay on here, as today. With them off at the org, GitHub
  # may refuse the repo module's own has_projects = false; that wasn't tried.
  has_organization_projects = true
  has_repository_projects   = true
}
