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

# zimmertr's repos from before Terraform (#8 steps 6.9 to 6.12). Each resource
# GitHub can import by the repo's name is imported, so the plan shows what
# actually changes. The rest are created: the rulesets don't exist yet,
# because these repos use classic branch protection, and creating each of the
# three restapi_object settings is a PUT or PATCH that sets what the module
# wants, whatever it was.
locals {
  zimmertr_imported = toset([
    for r in [
      "yggdrasil", "ai-config", "hevy-trainer-sync", "hevy-garmin-sync", "bluebird", "bluebird-helm",
      "Kubernetes-Manifests", "TJs-Kubernetes-Service", "Personal-Website", "zimmertr", "3D-Models", "Bootstrap-Proxmox",
      "Supermicro-X10-Fancontrol", "Mountaineers-Activity-Scraper", "Ender-6-Klipper-Guide", "Better-Lighter-Pack",
      "Strava-Heatmap-String-Builder", "Resume",
    ] :
    r if contains(keys(local.by_owner["zimmertr"]), r)
  ])
}

import {
  for_each = local.zimmertr_imported
  to       = module.zimmertr[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = local.zimmertr_imported
  to       = module.zimmertr[each.key].github_repository_vulnerability_alerts.this[0]
  id       = each.key
}

import {
  for_each = local.zimmertr_imported
  to       = module.zimmertr[each.key].github_repository_dependabot_security_updates.this[0]
  id       = each.key
}

import {
  for_each = local.zimmertr_imported
  to       = module.zimmertr[each.key].github_actions_repository_permissions.this[0]
  id       = each.key
}

# Rulesets that existed before the import, by ruleset id from
# GET /repos/zimmertr/<repo>/rulesets, 2026-11-10. hevy-garmin-sync was set up
# to the module's standard by hand; TJs-Kubernetes-Service's "main branch"
# ruleset becomes the module's "default branch" one.
locals {
  zimmertr_default_branch_rulesets = {
    for r, id in {
      "hevy-garmin-sync"       = 26784694
      "TJs-Kubernetes-Service" = 24812486
    } : r => id if contains(keys(local.by_owner["zimmertr"]), r)
  }
  zimmertr_release_tags_rulesets = {
    for r, id in {
      "hevy-garmin-sync" = 26784695
    } : r => id if contains(keys(local.by_owner["zimmertr"]), r)
  }
}

import {
  for_each = local.zimmertr_default_branch_rulesets
  to       = module.zimmertr[each.key].github_repository_ruleset.default_branch[0]
  id       = "${each.key}:${each.value}"
}

import {
  for_each = local.zimmertr_release_tags_rulesets
  to       = module.zimmertr[each.key].github_repository_ruleset.release_tags[0]
  id       = "${each.key}:${each.value}"
}
