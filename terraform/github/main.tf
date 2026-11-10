# Every file under repos/<owner>/<name>.yml is one repo. A file holds only
# what differs from local.defaults (decision records 0012, 0043).

locals {
  owners = ["zimmertr", "Bluebird-Forecast", "Fellfield-Game", "GPX-Search", "TJs-Kubernetes-Service", "Lakebagger"]

  # initialize-project's standard for what a repo file may set. These keys are
  # the only ones a file may use: security settings aren't here, because the
  # repo module always turns them on.
  defaults = {
    description     = ""
    homepage_url    = null
    topics          = []
    visibility      = "public"
    archived        = false
    is_template     = false
    has_discussions = false
    required_checks = []
  }

  # "<owner>/<name>" => the file's keys. An empty file decodes to null, which
  # merge turns into an empty object.
  files = {
    for f in fileset(var.repos_dir, "*/*.yml") :
    trimsuffix(f, ".yml") => merge(yamldecode(file("${var.repos_dir}/${f}")))
  }

  # Terraform drops an object's unknown attributes without a word, so a
  # misspelled key would be ignored. The precondition on output.repos refuses
  # one instead.
  unknown_keys = {
    for k, v in local.files : k => setsubtract(keys(v), keys(local.defaults))
    if length(setsubtract(keys(v), keys(local.defaults))) > 0
  }
  unknown_owners = setsubtract([for k in keys(local.files) : split("/", k)[0]], local.owners)

  repos = {
    for k, v in local.files : k => {
      owner    = split("/", k)[0]
      name     = split("/", k)[1]
      settings = merge(local.defaults, v)
    }
  }

  # name => settings, for one owner's module block.
  by_owner = {
    for o in local.owners : o => {
      for r in values(local.repos) : r.name => r.settings if r.owner == o
    }
  }
}

module "zimmertr" {
  source   = "../modules/repo"
  for_each = local.by_owner["zimmertr"]
  providers = {
    github  = github.zimmertr
    restapi = restapi.zimmertr
  }

  owner    = "zimmertr"
  name     = each.key
  settings = each.value
}

module "bluebird_forecast" {
  source   = "../modules/repo"
  for_each = local.by_owner["Bluebird-Forecast"]
  providers = {
    github  = github.bluebird_forecast
    restapi = restapi.bluebird_forecast
  }

  owner    = "Bluebird-Forecast"
  name     = each.key
  settings = each.value
}

module "fellfield_game" {
  source   = "../modules/repo"
  for_each = local.by_owner["Fellfield-Game"]
  providers = {
    github  = github.fellfield_game
    restapi = restapi.fellfield_game
  }

  owner    = "Fellfield-Game"
  name     = each.key
  settings = each.value
}

module "gpx_search" {
  source   = "../modules/repo"
  for_each = local.by_owner["GPX-Search"]
  providers = {
    github  = github.gpx_search
    restapi = restapi.gpx_search
  }

  owner    = "GPX-Search"
  name     = each.key
  settings = each.value
}

module "tjs_kubernetes_service" {
  source   = "../modules/repo"
  for_each = local.by_owner["TJs-Kubernetes-Service"]
  providers = {
    github  = github.tjs_kubernetes_service
    restapi = restapi.tjs_kubernetes_service
  }

  owner    = "TJs-Kubernetes-Service"
  name     = each.key
  settings = each.value
}

module "lakebagger" {
  source   = "../modules/repo"
  for_each = local.by_owner["Lakebagger"]
  providers = {
    github  = github.lakebagger
    restapi = restapi.lakebagger
  }

  owner    = "Lakebagger"
  name     = each.key
  settings = each.value
}

output "repos" {
  description = "Every managed repo, as owner/name."
  value       = sort(keys(local.repos))

  precondition {
    condition     = length(local.unknown_keys) == 0
    error_message = "Unknown keys in repo files: ${jsonencode(local.unknown_keys)}. A repo file may set only ${join(", ", keys(local.defaults))}."
  }

  precondition {
    condition     = length(local.unknown_owners) == 0
    error_message = "repos/ has folders for owners the stack doesn't manage: ${join(", ", local.unknown_owners)}. Add the owner to local.owners, providers.tf and a module block."
  }
}
