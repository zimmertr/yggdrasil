# One github and one restapi provider per owner: an App installation token
# reaches one owner only, and Terraform can't loop over providers. A new owner
# adds a pair here, a module block in main.tf and its name in local.owners.

provider "github" {
  alias = "zimmertr"
  owner = "zimmertr"
  token = var.github_tokens["zimmertr"]
}

provider "github" {
  alias = "bluebird_forecast"
  owner = "Bluebird-Forecast"
  token = var.github_tokens["Bluebird-Forecast"]
}

provider "github" {
  alias = "fellfield_game"
  owner = "Fellfield-Game"
  token = var.github_tokens["Fellfield-Game"]
}

provider "github" {
  alias = "gpx_search"
  owner = "GPX-Search"
  token = var.github_tokens["GPX-Search"]
}

provider "github" {
  alias = "tjs_kubernetes_service"
  owner = "TJs-Kubernetes-Service"
  token = var.github_tokens["TJs-Kubernetes-Service"]
}

provider "github" {
  alias = "lakebagger"
  owner = "Lakebagger"
  token = var.github_tokens["Lakebagger"]
}

# The three settings integrations/github lacks go through the REST API with
# the same token (decision record 0024).
locals {
  rest_headers = {
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }
}

provider "restapi" {
  alias                = "zimmertr"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["zimmertr"]}" })
}

provider "restapi" {
  alias                = "bluebird_forecast"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["Bluebird-Forecast"]}" })
}

provider "restapi" {
  alias                = "fellfield_game"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["Fellfield-Game"]}" })
}

provider "restapi" {
  alias                = "gpx_search"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["GPX-Search"]}" })
}

provider "restapi" {
  alias                = "tjs_kubernetes_service"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["TJs-Kubernetes-Service"]}" })
}

provider "restapi" {
  alias                = "lakebagger"
  uri                  = "https://api.github.com"
  write_returns_object = false
  headers              = merge(local.rest_headers, { Authorization = "Bearer ${var.github_tokens["Lakebagger"]}" })
}
