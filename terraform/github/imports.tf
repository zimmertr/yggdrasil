# Repos that existed before Terraform managed them. Once a repo is in state,
# its import block does nothing, so the blocks stay. Each one runs only when
# the repo's file is in repos/, which keeps the tests' fixtures apart.

# The six .github repos, made empty by hand on 2026-11-06, because an App
# can't create a repo under the zimmertr account (#8 step 6.17).
import {
  for_each = contains(keys(local.by_owner["zimmertr"]), ".github") ? toset([".github"]) : toset([])
  to       = module.zimmertr[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = contains(keys(local.by_owner["Bluebird-Forecast"]), ".github") ? toset([".github"]) : toset([])
  to       = module.bluebird_forecast[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = contains(keys(local.by_owner["Fellfield-Game"]), ".github") ? toset([".github"]) : toset([])
  to       = module.fellfield_game[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = contains(keys(local.by_owner["GPX-Search"]), ".github") ? toset([".github"]) : toset([])
  to       = module.gpx_search[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = contains(keys(local.by_owner["TJs-Kubernetes-Service"]), ".github") ? toset([".github"]) : toset([])
  to       = module.tjs_kubernetes_service[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = contains(keys(local.by_owner["Lakebagger"]), ".github") ? toset([".github"]) : toset([])
  to       = module.lakebagger[each.key].github_repository.this
  id       = each.key
}
