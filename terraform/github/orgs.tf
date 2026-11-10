# Every file under orgs/<name>.yml is one org. A file holds only what differs
# from local.org_defaults (decision record 0051).

locals {
  # zimmertr is a user account, which has no org settings.
  orgs = setsubtract(local.owners, ["zimmertr"])

  # The keys an org file may use. Everything else is the same on every org,
  # set in the org module. The billing email is public on purpose (TJ,
  # 2026-11-10).
  org_defaults = {
    billing_email    = "tj@tjzimmerman.com"
    name             = null
    description      = null
    blog             = null
    email            = null
    location         = null
    company          = null
    twitter_username = null
  }

  org_files = {
    for f in fileset(var.orgs_dir, "*.yml") :
    trimsuffix(f, ".yml") => merge(yamldecode(file("${var.orgs_dir}/${f}")))
  }

  org_settings = { for k, v in local.org_files : k => merge(local.org_defaults, v) }

  unknown_org_keys = {
    for k, v in local.org_files : k => setsubtract(keys(v), keys(local.org_defaults))
    if length(setsubtract(keys(v), keys(local.org_defaults))) > 0
  }
  unknown_orgs = setsubtract(keys(local.org_files), local.orgs)
}

module "bluebird_forecast_org" {
  source    = "../modules/org"
  count     = contains(keys(local.org_files), "Bluebird-Forecast") ? 1 : 0
  providers = { github = github.bluebird_forecast }
  settings  = local.org_settings["Bluebird-Forecast"]
}

module "fellfield_game_org" {
  source    = "../modules/org"
  count     = contains(keys(local.org_files), "Fellfield-Game") ? 1 : 0
  providers = { github = github.fellfield_game }
  settings  = local.org_settings["Fellfield-Game"]
}

module "gpx_search_org" {
  source    = "../modules/org"
  count     = contains(keys(local.org_files), "GPX-Search") ? 1 : 0
  providers = { github = github.gpx_search }
  settings  = local.org_settings["GPX-Search"]
}

module "tjs_kubernetes_service_org" {
  source    = "../modules/org"
  count     = contains(keys(local.org_files), "TJs-Kubernetes-Service") ? 1 : 0
  providers = { github = github.tjs_kubernetes_service }
  settings  = local.org_settings["TJs-Kubernetes-Service"]
}

module "lakebagger_org" {
  source    = "../modules/org"
  count     = contains(keys(local.org_files), "Lakebagger") ? 1 : 0
  providers = { github = github.lakebagger }
  settings  = local.org_settings["Lakebagger"]
}

output "orgs" {
  description = "Every managed org."
  value       = sort(keys(local.org_files))

  precondition {
    condition     = length(local.unknown_org_keys) == 0
    error_message = "Unknown keys in org files: ${jsonencode(local.unknown_org_keys)}. An org file may set only ${join(", ", keys(local.org_defaults))}."
  }

  precondition {
    condition     = length(local.unknown_orgs) == 0
    error_message = "orgs/ has files for orgs the stack doesn't manage: ${join(", ", local.unknown_orgs)}. Add the org to local.owners, providers.tf and a module block in repos and orgs."
  }
}
